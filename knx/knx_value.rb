=begin
Project Ansible  - An extensible home automation scripting framework
----------------------------------------------------
Copyright (c) 2011 Elias Karakoulakis <elias.karakoulakis@gmail.com>

SOFTWARE NOTICE AND LICENSE

Project Ansible is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

Project Ansible is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Project Ansible.  If not, see <http://www.gnu.org/licenses/>.

for more information on the LGPL, see:
http://en.wikipedia.org/wiki/GNU_Lesser_General_Public_License
=end

require 'ansible_value'

require 'knx_transceiver'
require 'knx_protocol'
require 'knx_tools'
require 'knx_dpt'

module Ansible
    
    module KNX
        
        # a KNXValue is a device-dependant datapoint. It is initialized by a  
        # DPT type name (e.g. "1.001" for binary switch) and is extended 
        # by the initializer with the corresponding DPT module (e.g. KNX::DPT1)
        # so as to handle DPT1 frames.
        # Each KNXValue is linked to zero or more group addresses, the first
        # of which will be the "update" value
        class KNXValue
            
            include AnsibleValue
            
            #
            # ------ CLASS VARIABLES & METHODS
            #
            @@ids = 0
            def KNXValue.id_generator
                @@ids = @@ids + 1
                return @@ids
            end
    
            # a Hash containing all known group addresses
            @@AllGroups = {}
            
            # the transceiver responsible for all things KNX
            @@transceiver = nil
            def KNXValue.transceiver; return @@transceiver; end
            def KNXValue.transceiver=(other); 
                @@transceiver = other if other.is_a? Ansible::KNX::KNX_Transceiver
            end
            
            #
            # ----- INSTANCE VARIABLES & METHODS
            #
                    
            # equality checking
            def == (other)
                return (other.is_a?(KNXValue) and (@id == other.id))
            end

            # set flag: knxvalue.flags[:r] = true
            # get flag: knxvalue.flags[:r]  (evaluates to true, meaning the read flag is set)
            attr_reader :flags
            attr_reader :groups 
            attr_reader :dpt_basetype, :dpt_subtype, :id
            attr_accessor :description
    
            # initialize a KNXValue
            # params: 
            #   dpt: string representing the DPT (datapoint type) of the value
            #       e.g. "5.001" meaning DPT5 percentage value (8-bit unsigned)
            #   groups: array of group addresses associated with this datapoint
            #   flags: hash of symbol=>boolean flags regarding its behaviour
            #       e.g. {:r => true} the value can only respond to read requests on the KNX bus.
            #       default flags: READ and WRITE
            #       c => Communication
            #       r => Read
            #       w => Write
            #       t => Transmit
            #       u => Update
            #       i => read on Init
            def initialize(dpt, groups=[], flags=nil)
                
                # init DPT info
                if md = /(\d*)\.(\d*)/.match(dpt) then
                    @dpt = dpt
                    @dpt_mod = Ansible::KNX.module_eval("DPT#{md[1]}")
                    raise "unknown/undeclared DPT module #{dpt}" unless @dpt_mod.is_a?Module
                    @parserclass = @dpt_mod.module_eval("DPT#{md[1]}_Frame")
                    raise "unknown/undeclared parser for DPT #{dpt}" unless @parserclass.ancestors.include?(DPTFrame)
                    @dpt_basetype = @dpt_mod::Basetype
                    raise "missing Basetype info for #{dpt}" unless @dpt_basetype.is_a?Hash
                    @dpt_subtype = @dpt_mod::Subtypes[md[2]]
                    raise "missing sybtype info for #{dpt}" unless @dpt_subtype.is_a?Hash
                    # extend this object with DPT-specific module 
                    self.extend(@dpt_mod)
                    # print out some useful debug info                    
                    puts "  dpt_basetype = #{@dpt_basetype},  dpt_subtype = #{@dpt_subtype}" if $DEBUG
                else
                    raise "invalid datapoint type (#{dpt})"
                end
                
                # array of GroupAddress objects associated with this datapoint
                # only the first address is used in a  write operation (TODO: CHECKME)
                @groups = case groups
                    when Fixnum then Array[group]
                    when String then Array[str2addr(groups)] 
                    when Array then groups
                end
                
                # store DPT info about these group addresses
                @groups.each { |grp|
                    # sanity check: is this groupaddr already decaled as a different basetype?
                    # FIXME: specs dont forbid it, only check required is datalength compatibility
                    if @@AllGroups[grp] and (old_dpt = @@AllGroups[grp][:dpt_basetype]) and not (old_dpt.eql?(@dpt_basetype))                           
                        raise "Group address #{addr2str(grp)} is already declared as DPT basetype #{old_dpt}!"
                    end
                    puts "adding groupaddr #{addr2str(grp,true) } (#{@dpt}: #{@dpt_subtype[:name]}), to global hash"
                    @@AllGroups[grp] = {:basetype => @dpt_basetype, :subtype => @dpt_subtype}
                }
                
                unless flags.nil?
                    raise "flags parameter must be a Hash!" unless flags.is_a?Hash
                end
                # default flags: READ and WRITE
                @flags = flags or {:r => true,:w => true}

                # TODO: physical address: set only for remote nodes we are monitoring
                # when left to nil, it/ means a datapoint on this KNXTransceiver 
                @physaddr = nil
                
                # id of datapoint
                # initialized by class method KNXValue.id_generator
                @id = KNXValue.id_generator()
                
                @description = ''
                
                # store this KNXValue in the Ansible database
                AnsibleValue.insert(self)
            end

            
            #
            #
            #
            #
            #
            def read_value()
                if (not @groups.nil?) and (group = @groups[0]) then
                    if (data = @@transceiver.read_eibd_cache(group)) then
                        fire_callback(:onReadCacheHit)
                        # update the value
                        update(@parserclass.read(data.pack('c*')))
                    else
                        # value not found in cache, maybe some other
                        # device on the bus will respond...
                        fire_callback(:onReadCacheMiss)
                        nil
                    end
                else
                    return false
                end
            end
            
            #
            # write value to the bus
            # argument: new_val according to DPT 
            #   if :basic, then new_val is plain data value   
            #   else (:composite) new_val is a hash of 
            #       field_name => field_value pairs
            #   all values get mapped using to_protocol_value() in AnsibleValue::update()
            # return true if successful, false otherwise
            def write_value(new_val)
                puts "#{self}: Writing new value (#{new_val}) to #{addr2str(dest, true)}"
                #write value to primary group address
                dest, telegram = nil, nil
                if @groups.length > 0 then 
                    dest = @groups[0]
                else
                    raise "#{self}: primary group address not set!!!"
                end 
                case @dpt_mod::Basetype[:valuetype]
                when :basic then
                    # basic value: single 'data' field
                    telegram = @parserclass.new(:data => new_val)
                when :composite then
                    if new_val.is_a?Hash then
                        telegram = @parserclass.new(new_val)
                    else
                        if @parserclass.methods.include?(:assign) then
                            puts "FIXME"
                        else
                            raise "#{self} has a composite DPT, set() expects a hash!"
                        end
                    end
                end
                if (@@transceiver.send_apdu_raw(dest, telegram.to_apdu(0x80) > -1)) then
                    update(telegram)
                    return(true)
                else
                    return(false)
                end
            end
            
            # set primary group address
            def group_primary=(grpaddr)
                @groups.unshift(grpaddr)
            end
            
            # assign a new array of group addresses for this datapoint
            def groups=(other)
                raise "KNXValue.groups= requires an array of at least one group addresses" unless (other.is_a?Array) and (other.length > 0)
                @groups.replace(other)
            end
            
            # make sure all frame fields are valid (within min,max range)
            # see Ansible::AnsibleValue.update
            def validate_ranges
                if defined? @current_value then  
                    @current_value.validate_ranges
                end
            end
            
            # create apdu for this KNXValue
            # APDU types are:
            #   0x00 => Read
            #   0x40 => Response (default)
            #   0x80 => Write
            def to_apdu(telegram, apci_code = 0x40)
                # funny this pops up: a comma sent NASA's Mariner 1 out of orbit...
                apdu = if @dpt_mod::Basetype[:bitlength] <= 6 then
                    #[0, apci_code | @current_value]
                    [0, apci_code | telegram.data]
                else
                    #[0, apci_code] + @current_value.to_a
                    [0, apci_code] + telegram.to_binary_s.unpack('C*') 
                end
                return apdu
            end
            
            # update internal state from raw KNX frame
            def update_from_frame(rawframe)
                data = if @dpt_mod::Basetype[:bitlength] <= 6 then
                    # bindata always expects a binary string
                    [rawframe.apci_data].pack('c')
                else
                    rawframe.data
                end
                foo = @parserclass.read(data)
                puts "update_from_frame: #{foo.class} = #{foo.inspect}"
                update(foo)
            end
                
            # human-readable representation of the value. Uses all field
            # info from its DPT included module, if available.
            def to_s
                dpt_name = (@dpt_subtype.nil?) ? '' : @dpt_subtype[:name] 
                dpt_info = "[#{@dpt} #{dpt_name}]"
                # add field values explanation, if any
                vstr = (defined?(@current_value) ? explain(@current_value) : '(value undefined)')
                # return @dpt: values.explained
                gaddrs = @groups.collect{|ga| addr2str(ga, true)}.join(', ')
                return [@description, gaddrs, dpt_info].compact.join(' ') + " : #{vstr}" 
            end
                        
            # return a human-readable representation of a DPT frame
            def explain(frame)
                raise "explain() expects a DPTFrame, got a #{frame.class}" unless frame.is_a?DPTFrame
                fielddata = []
                # iterate over all available DPT fields
                frame.field_names.each { |fieldname|
                    # skip padding fields
                    next if /pad/.match(fieldname)
                    field = frame.send(fieldname)
                    fval = field.value
                    # get value encoding hashmap, if any
                    vhash = getparam(:enc, field)
                    # get value units
                    units = getparam(:unit, field) 
                    fval = as_canonical_value()
                    # add field value, according to encoding hashtable
                    fielddata << "#{(vhash.is_a?Hash) ? vhash[fval] : fval} #{units}"
                } 
                return fielddata.join(', ')
            end            

            # get a DPT parameter, trying to locate it in the following order:
            #   1) in the DPTFrame field definition 
            #   2) in the DPT subtype definition
            #   3) in the DPT basetype definition
            def getparam(param, field=nil)
                return ((field and field.get_parameter(param)) or 
                        (@dpt_subtype and @dpt_subtype[param]) or 
                        (@dpt_basetype and @dpt_basetype[param]))
            end
            
        end #class KNXValue
    
    end #module KNX
    
end #module Ansible
