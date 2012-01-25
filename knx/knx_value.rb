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

module Ansible
    
    module KNX
        
    # a KNXValue is the device-dependant datapoint. It is the base class 
    # which all datapoint type classes will inherit. Every subclass
    # declares a base DPT: e.g.KNXValue_DPT1 is for 1-bit boolean values, 
    # KNXValue_DPT5 for 8-bit unsigned values etc. They can be subclassed
    # too so as to implement specific 2nd-level functionality e.g. 
    # KNXValue_DPT5[:001] is 5.001 percentage (0=0..ff=100%)
    # 
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
            return (@id == other.id)
        end
        
        attr_reader :groups, :flags, :dpt_basetype, :dpt_subtype, :id
        attr_accessor :description

        # initialize KNXValue
        # params: 
        #   groups: array of group addresses associated with this datapoint
        #   flags: hash of symbol=>boolean flags regarding  
        def initialize(dpt_type, groups=[], flags=nil)

            # datapoint type: string representing the DPT type of the value
            # e.g. "5.001" meaning DPT5 percentage value (8-bit unsigned)
            #   0x00=0%, 0xff = 100%
            # or "5.004" meaning DPT5 percentage value (8-bit unsigned)
            #   0x00=0%, 0xff = 255%
            if md = /(\d*)\.(\d*)/.match(dpt_type) then
                @dpt_type = dpt_type
                @dpt_mod = Ansible::KNX.module_eval("DPT#{md[1]}")
                raise "unknown/undeclared DPT type #{dpt_type}" unless @dpt_mod.is_a?Module
                @dpt_basetype = @dpt_mod::Basetype
                @dpt_subtype = @dpt_mod::Subtypes[md[2]]
                # extend this object with DPT-specific module 
                self.extend(@dpt_mod) 
            else
                raise "invalid DPT type (#{dpt_type})"
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
                # sanity check
                puts  "Warning: redeclaring Group address #{addr2str(grp)}!" if @@AllGroups[grp]
                if @@AllGroups[grp] and (old_dpt = @@AllGroups[grp][:dpt_basetype]) and not (old_dpt.eql?(@dpt_basetype))                           
                    raise "Group address #{addr2str(grp)} is already declared as DPT basetype #{old_dpt}!"
                end
                puts "adding groupaddr #{addr2str(grp,true) } (#{@dpt_type}: #{@dpt_subtype[:name]}), to global hash"
                @@AllGroups[grp] = {:basetype => @dpt_basetype, :subtype => @dpt_subtype}
            }
            
            # set flag: knxvalue.flags[:r] = true
            # get flag: knxvalue.flags[:r]  (evaluates to true, meaning the read flag is set)
            unless flags.nil?
                raise "flags parameter must be a Hash!" unless flags.is_a?Hash
            end
            # default flags: READ and WRITE
            @flags = flags or {:r => true,:w => true}
            # c => Communication
            # r => Read
            # w => Write
            # t => Transmit
            # u => Update
            # i => read on Init
                        
            # TODO: physical address: set only for remote nodes we are monitoring
            # when left to nil, it/ means a datapoint on this KNXTransceiver 
            @physaddr = nil
            
            # id of datapoint
            # initialized by class method KNXValue.id_generator
            @id = KNXValue.id_generator()
            
            # store this KNXValue in the Ansible database
            AnsibleValue.insert(self)
        end
        
        # get a value from eibd
        def get()
            
        end
        
        # set (write) a value to eibd
        def set(new_val)
            #write value to primary group address
            dest = nil
            if @groups.length > 0 then 
                dest = @groups[0]
            else
                raise "#{self}: primary group address not set!!!"
            end
            puts "#{self}: Writing value to #{addr2str(dest)}"
            #
            @@transceiver.send_apdu_raw(dest, create_apdu())
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
        def validate_ranges
            if @dpt_basetype[:valuetype] = :composite then
                # its a composite DPT (contains multiple fields)
                # range checking is global: applies to all subtypes
                @frame.field_names.each { |fieldname|
                    field = @frame.send(fieldname)
                    if range = field.options[:range] then
                        unless range === field.value
                            raise "#{self.class}: field #{fieldname} value (#{field.value}) out of range #{range}"
                        end
                    end
                }
            else
                # its a basic DPT (single data field)
                #FIXME
            end
        end
        
        # create apdu for this KNXValue
        # APDU types are:
        #   0x00 => Read
        #   0x40 => Response (default)
        #   0x80 => Write
        def to_apdu(apci_code = 0x40)
            # funny this pops up: a comma sent NASA's Mariner 1 out of orbit...
            apdu = if @dpt_mod::Basetype[:bitlength] <= 6 then
                #[0, apci_code | @current_value]
                [0, apci_code | @current_value.to_binary_s].pack('c*')
            else
                #[0, apci_code] + @current_value.to_a
                [0, apci_code].pack('c*') + @current_value.to_binary_s 
            end
            return apdu
        end
        
        # update internal state from raw KNX frame
        def update_from_frame(rawframe)
            data = if @dpt_mod::Basetype[:bitlength] <= 6 then
                #[rawframe.apci_data].pack('c')
                rawframe.apci_data
            else
                rawframe.data
            end
            #@frame = @dpt_mod::FrameStruct.new(data)
            @frame = @dpt_mod::FrameStruct.read(data)
            #puts "--- #{@dpt_mod} frame: #{@frame.inspect_detailed}"
            puts "--- #{@dpt_mod} frame: #{@frame.inspect}"
            update(@frame)
        end
            
        # human-readable representation of the value. Uses all field
        # info from its DPT included module, if available.
        def to_s
            # type name first (e.g. "DPT1.001"
            typeinfo = @dpt_type
            subtype = @dpt_subtype[:name]
            typeinfo << (subtype ? "(#{subtype})" : "")
            fielddata = []
            @frame.field_names.each { |fieldname|
                next if fieldname == /pad/
                field = @frame.send(fieldname)
                fielddata << (vhash = @dpt_subtype[:enc]) ? vhash[field.value] : field.value
            }
            return typeinfo + ":" + fielddata.join(', ')
        end
    end #class KNXValue
 
    #
    # load all known KNXValue_DPT** classes
    Dir["knx/dpt/*.rb"].each { |f| load f }
    
    end #module KNX
    
end #module Ansible
