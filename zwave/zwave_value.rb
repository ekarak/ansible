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

# load thrift-generated code
require 'thrift'
require 'ozw_constants'
require 'ozw-headers'
require "remote_manager"

require 'ansible_value'
require 'ansible_callback'

require 'zwave_protocol'
require 'zwave_command_classes'

module Ansible

    module ZWave 

        RefreshedNodes = {}
        
        # extend the Thrift ValueID interface with some interesting stuff
        class ValueID < OpenZWave::RemoteValueID
            include AnsibleValue
            include AnsibleCallback
            
            #
            # ------ CLASS VARIABLES & METHODS
            #
            @@transceiver = nil
            def ValueID.transceiver; return @@transceiver; end
            def ValueID.transceiver=(other); 
                @@transceiver = other if other.is_a? Ansible::ZWave::ZWave_Transceiver
            end
                
            # get existing ValueID object, or else create it
            def ValueID.get_or_create(homeid_str, valueid_str)
                query = AnsibleValue[:_homeId => homeid_str.to_i(16), :valueId => valueid_str.to_i(16)]
                value = (query.is_a?Array and query.size>0 and query[0]) or 
                        ValueID.new(homeid_str, valueid_str)
                return value
            end
            
            #
            # ----- INSTANCE VARIABLES & METHODS
            #
            
            attr_reader :valueId
            
            # equality checking
            def == (other)
                return (
                    other.is_a?(ValueID) and
                    (@_homeId == other._homeId) and (@valueId == other.valueId)
                )
            end
            
            # initialize ValueID by home and value id (both hex strings)
            def initialize( homeid_str, valueid_str)
                raise 'both arguments must be strings' if [homeid_str, valueid_str].find{|s| not s.is_a?String}
                
                # wARNING: instance variable naming must be consistent with ozw_types.rb (Thrift interface)
                @_homeId = homeid_str.to_i(16)
                @valueId  = valueid_str.to_i(16)
                # parse all fields
                m_id = OZW_ValueID_id.read([valueid_str.delete(' ')[-8..-1].to_i(16)].pack("N"))
                m_id1 = OZW_ValueID_id1.read([valueid_str.delete(' ')[0..-9].to_i(16)].pack("N"))
                # and store them
                @_nodeId = m_id.node_id
                @_genre = m_id.value_genre
                @_type = m_id.value_type
                @_valueIndex = m_id.value_idx
                @_commandClassId = m_id.cmd_class
                @_instance = m_id1.cmd_class_instance
                # access flags, default R/W
                @flags = {:r => true, :w => true}
                puts "NEW ZWAVE VALUE CREATED: #{self.inspect}" if $DEBUG
                
                if @_homeId > 0 then
                    # fill in some useful info so as not to query OpenZWave all the time
                    @flags[:readonly] = @@transceiver.manager_send(:IsValueReadOnly, self)
                    @flags[:writeonly] = @@transceiver.manager_send(:IsValueWriteOnly, self)
                end
                
                # time of last update
                @last_update = nil
                
                # a boolean flag set to true so as to know all subsequent notifications
                # by OpenZWave regarding this value have been caused by us
                @poll_delayed = false
                
                # dynamic binding to the corresponding OpenZWave data type
                @typename, @typedescr = OpenZWave::ValueTypes[@_type]
                @typemod = Ansible::ZWave.module_eval(@typename)
                raise "unknown/undeclared ZWave type module #{@typename}" unless @typemod.is_a?Module
                # extend this ValueID with type-specific module
                self.extend(@typemod)
                # store this ZWave ValueID in the Ansible database
                AnsibleValue.insert(self)
            end
                    
            
            # is this ZWave value read only?
            def read_only?
                (defined?@flags) and @flags[:readonly]
            end

            # is this ZWave value write only?
            def write_only?
                (defined?@flags) and @flags[:writeonly]
            end
            
            #
            # ZWave-specific: read value from the bus
            #
            def read_value()
                return(false) unless respond_to? :read_operation
                result = @@transceiver.manager_send(read_operation, self)
                if result and result.retval then
                    puts "#{self}.read_value() result == #{result.o_value}, Refreshed=#{RefreshedNodes[@_nodeId]}"
                    update(result.o_value)
                    return(true)
                else
                    return(false)
                end
            end
            
            #
            # ZWave-specific: write new value to OpenZWave
            # new_val must be in protocol form
            # return true if successful, false otherwise
            def write_value(new_val)
                return(false) unless respond_to? :write_operation
                if @@transceiver.manager_send(write_operation, self, new_val) then
                    # value can also be updated by ValueChanged notification
                    update(new_val) 
                    return(true)
                else
                    return(false)
                end
            end
        
            # return a reasonable string representation of the ZWave value
            def to_s
                return "ZWaveValue[n:#{@_nodeId} g:#{@_genre} cc:#{@_commandClassId} i:#{@_instance} vi:#{@_valueIndex} t:#{@_type}]==#{@current_value}(#{@current_value.class})"
            end
            
            # fetch all available ValueID info from OpenZWave
            def explain
                return(%Q{
        Value Label: #{ @@transceiver.manager_send(:GetValueLabel, self)}
        Value Help:  #{ @@transceiver.manager_send(:GetValueHelp, self)}
        
        Value Units: #{ @@transceiver.manager_send(:GetValueUnits, self)}
        Value Min:   #{ @@transceiver.manager_send(:GetValueMin, self)}
        Value Max:   #{ @@transceiver.manager_send(:GetValueMax, self)}
        
        Value read-only?  #{ @@transceiver.manager_send(:IsValueReadOnly, self)}
        Value write-only? #{ @@transceiver.manager_send(:IsValueWriteOnly, self)}
        Value set?        #{ @@transceiver.manager_send(:IsValueSet, self)}
})
            end
            
        end # class
        
        #
        # load all known ZWave type modules
        Dir["zwave/types/*.rb"].each { |f| load f }
        
    end #module ZWave
    
end #module Ansible
