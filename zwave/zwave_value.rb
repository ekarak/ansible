#~ Project Ansible
#~ (c) 2011 Elias Karakoulakis <elias.karakoulakis@gmail.com>

require 'thrift'

# load thrift-generated code 
$:.push("/home/ekarak/ozw/Thrift4OZW/gen-rb")
require 'ozw_constants'
require 'ozw-headers'
require "remote_manager"

require 'ansible_value'
require 'zwave_protocol'
require 'zwave_command_classes'

module OpenZWave

# some useful lookup tables
cpp_src = "/home/ekarak/ozw/open-zwave-read-only/cpp/src"
NotificationTypes, ValueGenres, ValueTypes = parse_ozw_headers(cpp_src) # in ozw-headers.rb
#CommandClassesByID defined in zwave_command_classes.rb

RefreshedNodes = {}

# extend the Thrift ValueID interface with some interesting stuff
class ValueID < RemoteValueID
    include AnsibleValue
    
    #
    # ------ CLASS VARIABLES & METHODS
    #
    @@NodesPolled = {}
    
    
    #
    # ----- INSTANCE VARIABLES & METHODS
    #
    
    attr_reader :value_id, :poll_delayed
    
    # equality checking
    def == (other)
        return ((@_homeId == other._homeId) and (@value_id == other.value_id))
    end
    
    # initialize ValueID by home and value id (both hex strings)
    def initialize(transceiver, homeid, valueid)
        @transceiver = transceiver
        
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
        @readonly = @transceiver.manager_send(:IsValueReadOnly, self)
        
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
            when RemoteValueType::ValueType_Bool then :GetValueAsBool
            when RemoteValueType::ValueType_Byte then :GetValueAsByte
            when RemoteValueType::ValueType_Int    then :GetValueAsInt
            when RemoteValueType::ValueType_Short then :GetValueAsShort
            when RemoteValueType::ValueType_Decimal then :GetValueAsFloat #FIXME
            when RemoteValueType::ValueType_String then :GetValueAsString
            when RemoteValueType::ValueType_List then :GetValueListItems
            when RemoteValueType::ValueType_Button then  :GetValueAsString #FIXME
            #FIXME: when RemoteValueType::ValueType_Schedule
        else raise "unknown/uninitialized value type! #{inspect}"
        end
        result = @transceiver.manager_send(operation, self)
        if result and result.retval then
            puts "get() result=#{result.o_value}, prev=#{@previous_value.inspect} curr=#{@current_value.inspect} Refreshed=#{RefreshedNodes[@_nodeId]}"
            # call succeeded, let's see what we got from OpenZWave
            if (@current_value == result.o_value) and not RefreshedNodes[@_nodeId] then
                #ZWave peculiarity: we got a ValueChanged event, but the value
                # reported by OpenZWave is unchanged. Thus we need to RefreshNodeInfo
                @poll_delayed = true
                trigger_change_monitor
            end
            update(result.o_value)
            fire_callback(:onAfterGet)
            return(result)
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
            when RemoteValueType::ValueType_Bool then :SetValue_Bool
            when RemoteValueType::ValueType_Byte then :SetValue_UInt8
            when RemoteValueType::ValueType_Int then :SetValue_Int32
            when RemoteValueType::ValueType_Short then :SetValue_Int16
            when RemoteValueType::ValueType_Decimal then :SetValue_Float
            when RemoteValueType::ValueType_String then :SetValue_String
            when RemoteValueType::ValueType_List then :SetValueListSelection
            when RemoteValueType::ValueType_Button then :SetValue_String #FIXME 
            #FIXME: when RemoteValueType::ValueType_Schedule
        end #case
        result = false
        if result = @transceiver.manager_send(operation, self, new_val) then
            update(new_val)
            fire_callback(:onAfterSet)
            return(result)
        else
            raise "SetValue failed for #{self}"
        end
    end
    
    # update internal instance variable representing the current state of the value 
    def update(newval)
        unless @current_value == newval then
            @last_update = Time.now
            puts "==> updating value #{self}, with #{newval.inspect}"        
            # previous value was different, update it and fire onUpdate handler
            @previous_value = @current_value
            @current_value = newval
            # trigger onUpdate callback, if any
            fire_callback(:onUpdate, @current_value)
        end
    end
    

    # Zwave value notification system only informs us about  a 
    # value being changed (ie by manual operation or by an
    # external command). 
    def trigger_change_monitor
        unless @@NodesPolled[@_nodeId] then
            @@NodesPolled[@_nodeId] = true
            # spawn new polling thread
            @poll_thread = Thread.new {
                puts "==> spawning trigger change monitor thread #{Thread.current} for node: #{@_nodeId}<=="
                begin
                    fire_callback(:onChangeMonitorStart, @_nodeId) 
                    # request node status update
                    sleep(1)
                    @transceiver.manager_send(:RefreshNodeInfo, Ansible::HomeID, @_nodeId) 
                    fire_callback(:onChangeMonitorComplete, @_nodeId)
                    puts "==> trigger change monitor thread (#{Thread.current} ENDED<=="
                    @@NodesPolled[@_nodeId] = false
                rescue Exception => e
                    puts "#{e}:\n\t" + e.backtrace.join("\n\t")
                end
            }
        end
    end

end # class
    
end #module