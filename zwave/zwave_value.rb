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

require 'thrift'

# load thrift-generated code 
$:.push("/home/ekarak/ozw/Thrift4OZW/gen-rb")
require 'ozw_constants'
require 'ozw-headers'
require "remote_manager"

require 'ansible_value'
require 'ansible_callback'

require 'zwave_protocol'
require 'zwave_command_classes'

# some useful lookup tables
cpp_src = "/home/ekarak/ozw/open-zwave-read-only/cpp/src"
NotificationTypes, ValueGenres, ValueTypes = parse_ozw_headers(cpp_src) # in ozw-headers.rb
#CommandClassesByID defined in zwave_command_classes.rb

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
            @@NodesPolled = {}
            @@transceiver = nil
            def ValueID.transceiver; return @@transceiver; end
            def ValueID.transceiver=(other); 
                @@transceiver = other if other.is_a? Ansible::ZWave_Transceiver
            end
                
            #
            # ----- INSTANCE VARIABLES & METHODS
            #
            
            attr_reader :value_id, :poll_delayed
            
            # equality checking
            def == (other)
                return (
                    other.is_a?(ValueID) and
                    (@_homeId == other._homeId) and (@value_id == other.value_id)
                )
            end
            
            # initialize ValueID by home and value id (both hex strings)
            def initialize( homeid, valueid)
                raise 'both arguments must be strings' unless ((homeid.is_a?String) and (valueid.is_a?String))
                
                @_homeId = homeid.to_i(16)
                @value_id  = valueid
                #
                @id = [valueid.delete(' ')[-8..-1].to_i(16)].pack("N")
                @id1 = [valueid.delete(' ')[0..-9].to_i(16)].pack("N")
                # parse all fields
                b = OZW_EventID_id.new(@id)
                b1 = OZW_EventID_id1.new(@id1)
                # and store them
                @_nodeId = b.node_id
                @_genre = b.value_genre
                @_type = b.value_type
                @_valueIndex = b.value_idx
                @_commandClassId = b.cmd_class
                @_instance = b1.cmd_class_instance
                puts "NEW ZWAVE VALUE CREATED: #{self.inspect}" if $DEBUG
                
                # fill in some useful info so as not to query OpenZWave all the time
                @readonly = @@transceiver.manager_send(:IsValueReadOnly, self)
                
                # time of last update
                @last_update = nil
                
                # a boolean flag set to true so as to know all subsequent notifications
                # by OpenZWave regarding this value have been caused by us
                @poll_delayed = false
            end
            
            #
            # get a value
            # returns the current value stored in OpenZWave, 
            # OR raise exception if the call to OpenZWave failed 
            def get()
                fire_callback(:onBeforeGet)
                puts "get() called for #{self.inspect} by:\n\t" + caller[0..2].join("\n\t") if $DEBUG
                #
                operation = case @_type
                    when OpenZWave::RemoteValueType::ValueType_Bool then :GetValueAsBool
                    when OpenZWave::RemoteValueType::ValueType_Byte then :GetValueAsByte
                    when OpenZWave::RemoteValueType::ValueType_Int    then :GetValueAsInt
                    when OpenZWave::RemoteValueType::ValueType_Short then :GetValueAsShort
                    when OpenZWave::RemoteValueType::ValueType_Decimal then :GetValueAsFloat #FIXME
                    when OpenZWave::RemoteValueType::ValueType_String then :GetValueAsString
                    when OpenZWave::RemoteValueType::ValueType_List then :GetValueListItems
                    when OpenZWave::RemoteValueType::ValueType_Button then  :GetValueAsString #FIXME
                    #FIXME: when RemoteValueType::ValueType_Schedule
                else raise "unknown/uninitialized value type! #{inspect}"
                end
                result = @@transceiver.manager_send(operation, self)
                if result and result.retval then
                    puts "get() result=#{result.o_value}, curr=#{@current_value.inspect} Refreshed=#{RefreshedNodes[@_nodeId]}"
                    # call succeeded, let's see what we got from OpenZWave
                    fire_callback(:onAfterGet)
                    # update the current value and return
                    # the new current value to our callers
                    return(update(result.o_value))
                else
                    raise "value #{self}: call to #{operation} failed!!"
                end
            end
            
            # set a value 
            # arg1: the new value, must be ruby-castable to OpenZWave's type system
            # returns: true on success, raises exception on error
            #WARNING: a true return value doesn't mean the command actually succeeded, 
            # it only means that it was queued for delivery to the target node
            def set(new_val)
                fire_callback(:onBeforeSet)
                operation = case @_type
                    when OpenZWave::RemoteValueType::ValueType_Bool then :SetValue_Bool
                    when OpenZWave::RemoteValueType::ValueType_Byte then :SetValue_UInt8
                    when OpenZWave::RemoteValueType::ValueType_Int then :SetValue_Int32
                    when OpenZWave::RemoteValueType::ValueType_Short then :SetValue_Int16
                    when OpenZWave::RemoteValueType::ValueType_Decimal then :SetValue_Float
                    when OpenZWave::RemoteValueType::ValueType_String then :SetValue_String
                    when OpenZWave::RemoteValueType::ValueType_List then :SetValueListSelection
                    when OpenZWave::RemoteValueType::ValueType_Button then :SetValue_String #FIXME 
                    #FIXME: when RemoteValueType::ValueType_Schedule
                end #case
                result = false
                #special case
                if [TrueClass, FalseClass].include?(new_val.class)
                    new_val = new_val ? 1 : 0
                end
                if result = @@transceiver.manager_send(operation, self, new_val) then
                    fire_callback(:onAfterSet)
                    # update the current value
                    update(new_val)
                    return(result)
                else
                    raise "SetValue failed for #{self}"
                end
            end
            
            # called by the transceiver on all values that received a ValueChanged 
            # notification. NOTICE! we need to do some polling if the value returned
            # by the library is the same...
            def changed
                result = get()
                if (@current_value == result) and not Ansible::ZWave::RefreshedNodes[@_nodeId]  then
                    #ZWave peculiarity: we got a ValueChanged event, but the value
                    # reported by OpenZWave is unchanged. Thus we need to poll the
                    # device using :RequestNodeDynamic, wait for NodeQueriesComplete
                    # then re-get the value
                    trigger_change_monitor
                else
                    # update the current value
                    update(result)
                end
            end
                
            # Zwave value notification system only informs us about  a 
            # value being changed (ie by manual operation or by an
            # external command). 
            def trigger_change_monitor
                @poll_delayed = true
                unless @@NodesPolled[@_nodeId] then
                    @@NodesPolled[@_nodeId] = true
                    # spawn new polling thread
                    @poll_thread = Thread.new {
                        puts "==> spawning trigger change monitor thread #{Thread.current} for node: #{@_nodeId}<=="
                        begin
                            fire_callback(:onChangeMonitorStart, @_nodeId) 
                            # request node status update after 1 sec
                            sleep(2)
                            @@transceiver.manager_send(:RequestNodeDynamic, Ansible::HomeID, @_nodeId)
                            #@transceiver.manager_send(:RefreshNodeInfo, Ansible::HomeID, @_nodeId)
                            sleep(1)
                            fire_callback(:onChangeMonitorComplete, @_nodeId)
                            puts "==> trigger change monitor thread (#{Thread.current} ENDED<=="
                            @@NodesPolled[@_nodeId] = false
                            @poll_delayed = false
                        rescue Exception => e
                            puts "#{e}:\n\t" + e.backtrace.join("\n\t")
                        end
                    }
                end
            end
        
        end # class
    end #module ZWave
end #module Ansible