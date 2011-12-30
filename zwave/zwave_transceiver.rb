#~ Project Ansible
#~ (c) 2011 Elias Karakoulakis <elias.karakoulakis@gmail.com>

require 'rubygems'
require 'onstomp'
require 'thrift'

require 'zwave_protocol'
require 'zwave_value'
require 'transceiver'

###################
#ZWAVE MONITOR TOPIC: 
#   passes all ZWave activity to STOMP
#   ZWave frame headers as defined in zwave-protocol.rb
ZWAVE_MONITOR_TOPIC = "/queue/zwave/monitor"

#################
# ZWAVE_COMMAND_TOPIC
#   header =>
#   body => 
#ZWAVE_COMMAND_TOPIC = "/queue/knx/command"

module Ansible

    ThriftPort = 9090
    HomeID = 0x00006258

    class ZWave_Transceiver < Transceiver
        
        attr_reader :stompURL, :thriftURL
        
        def initialize(stompURL, thriftURL)
            puts "#{self}: initializing" if $DEBUG
            @stompURL, @thriftURL = stompURL, thriftURL
            #@stompMutex = Mutex.new
            @thriftMutex = Mutex.new
            @stomp_ok, @thrift_ok = false, false
            @alive = true
            super()
        end
        
        # initialize connection to STOMP server
        def init_stomp
            unless @stomp_ok
                begin
                    #puts "init_stomp\n-------------\n\t" +  caller.join("\n\t") + "\n"
                    @stompserver = OnStomp::Client.new(@stompURL)
                    @stompserver.on_connection_died { |client, con|
                        @stomp_ok = false
                        puts "STOMP connection died!! sleeping for 3 seconds and then retrying..."
                        puts "stack trace: \n\t"<< caller.join("\t\n")
                        sleep(3)
                        @stompserver.connect
                    }
                    #
                    @stompserver.on_connection_closed { |client, con|
                        @stomp_ok = false
                        puts "STOMP connection closed!! sleeping for 10 seconds and then retrying..."
                        puts "stack trace: \n\t"<< caller.join("\t\n")
                        sleep(10)
                        @stompserver.connect
                    }
                    #
                    @stompserver.on_connection_established { |client, con|
                        puts "STOMP: Connected to broker using protocol version #{con.version}"
                        @stomp_ok = true
                    }
                    @stompserver.connect
                rescue Errno::ECONNREFUSED => e
                    @stomp_ok = false
                    puts "#{e}"
                end
            end
            return @stompserver
        end
        
        # get handle to stomp server, connect unless already connected
        # caller must unlock @stompMutex when done with stomp
        def stomp
            @stomp_ok ? @stompserver : init_stomp()
        end
        
        # initialize connection to THRIFT server
        ThriftURL_RE = /thrift:\/\/([^:]*)(?::(.*))*/
        def init_thrift()
            unless @thrift_ok
                # connect to Thrift server for OpenZWave
                begin
                    if md = ThriftURL_RE.match(@thriftURL) then
                        host = md[1]
                        port = md[2].nil?? 9090: md[2].to_i
                        #puts "THRIFT host, port = #{host}:#{port}"
                        @thrift_transport = Thrift::BufferedTransport.new(Thrift::Socket.new(host, port))
                        @thrift_protocol = Thrift::BinaryProtocol.new(@thrift_transport)
                        @thrift_transport.open()
                        @manager = ::OpenZWave::RemoteManager::Client.new(@thrift_protocol)
                        # fetch all known ValueID's from the server
                        @manager.SendAllValues
                        @thrift_ok = true
                        @thrift_heartbeat = Thread.new{
                            puts "Thrift: New heartbeat thread, #{Thread.current}"
                            # aargh, ugly heartbeat
                            while (@thrift_ok) do
                                manager_send(:GetControllerNodeId, HomeID)
                                #puts 'ping...'
                                sleep(1)
                            end
                            puts "Thrift: heartbeat thread exiting, #{Thread.current}"
                        }
                    else
                        raise "Thrift URL invalid"
                    end
                #rescue Thrift::TransportException => e
                rescue Exception => e
                    @thrift_ok = false
                    puts "#{e}"
                end
            end
            return @manager
        end
        
        # get handle to OpenZWave::RemoteManager 
        def manager
            # TODO: add caller watch here, (check for unsynchronized access)
            @thrift_ok ? @manager : init_thrift() 
        end
         
        # the preferred method to access OpenZWave::Manager methods
        # is via this generic call function, which takes care of all the nitty-gritty
        # details such as connection monitoring and thread synchronization
        def manager_send(meth, *args)
            result = nil
            @thriftMutex.synchronize{
                begin
                    result = manager.method(meth).call(*args)
                rescue Thrift::TransportException => e
                    @thrift_ok = false
                    puts "Thrift transport exception: retrying in 1 sec..."
                    puts "... meth=#{meth.inspect}, caller=#{caller[0]}"
                    sleep(1)
                    retry
                 rescue Exception => e
                     @thrift_ok = false
                     puts "Other exception: #{e}"
                     puts "... meth=#{meth.inspect}, caller=#{caller[0]}"
                end
            }
            return(result)
        end

        # main loop, runs in its own Ruby thread
        def run
            #
            # 1) subscribe to zwave's notification channel 
            #
            stomp.subscribe '/queue/zwave/monitor' do |msg|
                # Invoked every time the broker delivers a MESSAGE frame for the
                # SUBSCRIBE frame generated by this method call.
                puts "\n------ ZWAVE MESSAGE (#{Time.now}) ------" if $DEBUG
                    decode_monitor(msg)
            end # do subscribe
            # 
            # 2) Sleep forever (how pretty)
            #
            while true #@alive
                sleep(1)
            end
        end #def
        
        def decode_monitor(msg)
            begin
                #puts "decoding STOMP monitor frame...."
                value = nil
                if msg.headers["HomeID"] and msg.headers["ValueID"] then 
                    homeID = msg.headers["HomeID"]
                    valueID = msg.headers["ValueID"]
                    # lookup or create value
                    # pass self as an argument so as to receive manager operations
                    value = AnsibleValue.insert(OpenZWave::ValueID.new(self, homeID, valueID))
                end
                #
                if msg.headers["NotificationType"] then
                    notification_byte = msg.headers["NotificationByte"].to_i(16)
                    notification_type = msg.headers["NotificationType"].to_i(16)
                    notification_node = msg.headers["NotificationNodeId"].to_i(16)
                    #puts "Notification: #{OpenZWave::NotificationTypes[notification_type]}"
                    name, desc = OpenZWave::NotificationTypes[notification_type]
                    # dynamic notification handler dispatch
                    __send__("notification_"+name, notification_node, value)
                end
            rescue Exception => e
                puts "decode_monitor exception: #{e}"
                puts "\t"+e.backtrace[0..3].join("\n\t")
            end
        end

        def notification_Type_ValueAdded(nodeId, value)
                #@@Values[homeID].push(value)
        end
        
        def notification_Type_ValueRemoved(nodeId, value)            
                #  A node value has been removed from OpenZWave's list.  This only occurs when a node is removed. 
                #@@Values[homeID].delete(value)
        end
                        
        def notification_Type_ValueChanged(nodeId, value) 
            #  A node value has been updated from the Z-Wave network. */
            puts "Notification: ValueChanged #{value}"
            # get new state
           # value.trigger_change_monitor
           value.get
            #OpenZWave::ValueID.mark_node_dirty(notification_node)
            #OpenZWave::ValueID.trigger_change_monitor(notification_node)
        end
        
        def notification_Type_Group(nodeId, value) 
            # The associations for the node have changed. The application should rebuild any group information it holds about the node. */
            puts 'Notification: Group (TODO)'
        end
                    
        def notification_Type_NodeNew(nodeId, value) 
            # A new node has been found (not already stored in zwcfg*.xml file) */
            puts 'Notification: NodeNew (TODO)'
        end
                    
        def notification_Type_NodeAdded(nodeId, value) 
            # A new node has been added to OpenZWave's list.  This may be due to a device being added to the Z-Wave network, or because the application is initializing itself. */
            puts 'Notification: NodeAdded (TODO)'
        end
                    
        def notification_Type_NodeRemoved(nodeId, value) 
            # A node has been removed from OpenZWave's list.  This may be due to a device being removed from the Z-Wave network, or because the application is closing. */
            puts 'Notification: NodeRemoved'
        end
                    
        def notification_Type_NodeProtocolInfo(nodeId, value) 
            # Basic node information has been receievd, such as whether the node is a listening device, a routing device and its baud rate and basic, generic and specific types. It is after this notification that you can call Manager::GetNodeType to obtain a label containing the device description. */
            puts 'Notification: NodeProtocolInfo'
        end
                    
        def notification_Type_NodeNaming(nodeId, value) 
            # One of the node names has changed (name, manufacturer, product). */
            puts 'Notification: NodeNaming'
        end
                    
        def notification_Type_NodeEvent(nodeId, value) 
            # A node has triggered an event.  This is commonly caused when a node sends a Basic_Set command to the controller.  The event value is stored in the notification. */
            puts 'Notification: NodeEvent'
        end
                    
        def notification_Type_PollingDisabled(nodeId, value) 
            # Polling of a node has been successfully turned off by a call to Manager::DisablePoll */
            puts 'Notification: PollingDisabled'
        end
                    
        def notification_Type_PollingEnabled(nodeId, value) 
            # Polling of a node has been successfully turned on by a call to Manager::EnablePoll */
            puts 'Notification: PollingEnabled'
        end
                    
        def notification_Type_DriverReady(nodeId, value) 
            # A driver for a PC Z-Wave controller has been added and is ready to use.  The notification will contain the controller's Home ID, which is needed to call most of the Manager methods. */
            puts 'Notification: DriverReady'
        end
                    
        def notification_Type_DriverFailed(nodeId, value) 
            # Driver failed to load */
            puts 'Notification: DriverFailed'
        end
                    
        def notification_Type_DriverReset(nodeId, value) 
            # All nodes and values for this driver have been removed.  This is sent instead of potentially hundreds of individual node and value notifications. */
            puts 'Notification: DriverReset'
        end
                    
        def notification_Type_MsgComplete(nodeId, value) 
            # The last message that was sent is now complete. */
            puts 'Notification: MsgComplete'
        end
                    
        def notification_Type_EssentialNodeQueriesComplete(nodeId, value) 
            # The queries on a node that are essential to its operation have been completed. The node can now handle incoming messages. */
            puts "Notification: EssentialNodeQueriesComplete  (node:#{nodeId})"
            puts "==> marking node #{nodeId} as refreshed"
            OpenZWave::RefreshedNodes[nodeId] = true
        end
                    
        def notification_Type_NodeQueriesComplete(nodeId, value) 
            # All the initialisation queries on a node have been completed. */
            puts "Notification: NodeQueriesComplete (node:#{nodeId})"
            if OpenZWave::RefreshedNodes[nodeId] then
                AnsibleValue[:_nodeId => nodeId].each { |val|
                    val.get
                }
                # mark node as not refreshed, meaning all calls to GetValue 
                # should be taken with a grain of salt
                puts "==> marking node #{nodeId} as NOT refreshed"
                OpenZWave::RefreshedNodes[nodeId] = false
            end
        end
                    
        def notification_Type_AwakeNodesQueried(nodeId, value) 
            # All awake nodes have been queried, so client application can expected complete data for these nodes. */
            puts 'Notification: AwakeNodeQueried'
        end
                    
        def notification_Type_AllNodesQueried(nodeId, value) #
            puts 'Notification: AllNodesQueried'
        end        
        
    end #class
    
end # module Ansible