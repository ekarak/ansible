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

require 'rubygems'
require 'onstomp'
require 'thrift'

require 'config'
require 'zwave_protocol'
require 'zwave_value'
require 'transceiver'

module Ansible

    module ZWave
        
        # the ZWave transceiver is responsible for communication with the ZWave network 
        # uses ozwd, a Thrift wrapper around the OpenZWave library
        class ZWave_Transceiver < Transceiver
                 
            # we also use callbacks
            include AnsibleCallback
            
            attr_reader :stompURL, :thriftURL
            
            def initialize(stompURL, thriftURL)
                raise "Already initialized!" unless Ansible::ZWave::ValueID::transceiver.nil?
                puts "#{self}: initializing" if $DEBUG
                @stompURL, @thriftURL = stompURL, thriftURL
                #@stompMutex = Mutex.new
                @thriftMutex = Mutex.new
                @stomp_ok, @thrift_ok = false, false
                @alive = true
                super()
                # store reference to ourselves to the classes that use us
                Ansible::ZWave::ValueID.transceiver = self
                
                @ValueMonitors = {}
                @ValueMonitorMutex = Mutex.new
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
            
            # Thrift URL Regexp
            ThriftURL_RE = /thrift:\/\/([^:]*)(?::(.*))*/
            
            # initialize connection to THRIFT server
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
                                    sleep(1)
                                    #puts 'ping...'
                                    manager_send(:GetControllerNodeId, HomeID)
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
                @thriftMutex.synchronize {
                    begin
                        result = manager.method(meth).call(*args)
                    rescue Thrift::TransportException => e
                        @thrift_ok = false
                        puts "Thrift transport exception: retrying in 1 sec..."
                        puts "... meth=#{meth.inspect}, callers=\n\t" + caller.join("\n\t")
                        sleep(1)
                        retry
                     rescue Exception => e
                         @thrift_ok = false
                         puts "Other exception: #{e}"
                         puts "... meth=#{meth.inspect}, callers=\n\t" + caller.join("\n\t")
                    end
                }
                return(result)
            end
    
            #
            # transceiver main loop, runs in its own Ruby thread
            #
            def run
                # 1) subscribe to zwave's notification channel 
                stomp.subscribe '/queue/zwave/monitor' do |msg|
                    # Invoked every time the broker delivers a MESSAGE frame for the
                    # SUBSCRIBE frame generated by this method call.
                    puts "\n------ ZWAVE MESSAGE (#{Time.now}) ------" if $DEBUG
                    begin
                        value = nil
                        # lookup or create ValueID related to Notification
                        if msg.headers["HomeID"] and msg.headers["ValueID"] then 
                            homeID = msg.headers["HomeID"]
                            valueID = msg.headers["ValueID"]
                            # sync current HomeID
                            h = homeID.to_i(16)
                            unless Ansible::ZWave.const_defined?(:HomeID) then
                                if h > 0 then
                                    puts "------ SETTING HOME ID: #{homeID}"
                                    Ansible::ZWave.const_set("HomeID", h) 
                                end
                            end
                            # get or create ValueID object
                            value = Ansible::ZWave::ValueID.get_or_create(homeID, valueID)
                        end
                        # bind other notification parameters
                        if msg.headers["NotificationType"] then
                            node = msg.headers["NotificationNodeId"].to_i(16)
                            byte = msg.headers["NotificationByte"].to_i(16)
                            notif_type = msg.headers["NotificationType"].to_i(16)
                            name, desc = OpenZWave::NotificationTypes[notif_type]
                            # dynamic notification handler dispatch mechanism
                            if md = /Type_(.*)/.match(name) then
                                handler = "notification_" + md[1]
                                puts "#{handler} (n:#{node}) (b:#{byte}) (#{value})"
                                __send__(handler, node, byte, value) if respond_to?(handler)
                                # fire all notification-related callbacks for the value, if any
                                # e.g. onValueChanged, onValueRefreshed etc.
                                if value.is_a?AnsibleValue then
                                    value.fire_callback("on#{md[1]}".to_sym)
                                end
                            end
                        end
                        # controller state change notification mechanism
                        if ctrl_state = msg.headers["ControllerState"] then
                            controller_state(ctrl_state.to_i(16))
                        end
                    rescue Exception => e
                        puts "ZWaveTransceiver::decode_monitor() exception: #{e}"
                        puts "\t"+e.backtrace[0..3].join("\n\t")
                    end
                end # do subscribe
                # 2) Sleep forever (how pretty)
                while true #@alive #FIXME
                    sleep(1)
                end
            end
            
            
            #
            #
            # NOTIFICATIONS
            #
            
            # a value has been added to the Z-Wave network
            def notification_ValueAdded(nodeId, byte, value)
                    #@@Values[homeID].push(value)
            end
            
            # a value has been removed from the Z-Wave network
            def notification_ValueRemoved(nodeId, byte, value)            
                    #  A node value has been removed from OpenZWave's list.  This only occurs when a node is removed. 
                    #@@Values[homeID].delete(value)
            end
                
            #  A node value has been updated from the Z-Wave network.            
            def notification_ValueChanged(nodeId, byte, value)               
                # OpenZWave peculiarity: we got a ValueChanged event, but the value
                # reported by OpenZWave is unchanged. Thus we need to poll the
                # device using :RequestNodeDynamic, wait for NodeQueriesComplete
                # then re-get the value
                trigger_value_monitor(value)
            end
            
            #  A node value has been refreshed from the Z-Wave network.
            def notification_ValueRefreshed(nodeId, byte, value) 
                puts "Value #{value} refreshed!!!"
            end
            
            # The associations for the node have changed. The application 
            # should rebuild any group information it holds about the node.
            def notification_Group(nodeId, byte, value) 
                puts 'TODO'  
            end
                        
            # A new node has been found (not already stored in zwcfg*.xml file)
            def notification_NodeNew(nodeId, byte, value) 
                puts 'TODO'
            end
                        
            # A new node has been added to OpenZWave's list.  This may be due 
            # to a device being added to the Z-Wave network, or because the 
            # application is initializing itself.
            def notification_NodeAdded(nodeId, byte, value) 
                puts 'TODO'
            end
                
            # A node has been removed from OpenZWave's list.  This may be due 
            # to a device being removed from the Z-Wave network, or because 
            # the application is closing.
            def notification_NodeRemoved(nodeId, byte, value) 
                puts 'TODO'    
            end

            # Basic node information has been receievd, such as whether 
            # the node is a listening device, a routing device and its 
            # baud rate and basic, generic and specific types. It is 
            # after this notification that you can call Manager::GetNodeType 
            # to obtain a label containing the device description. */            
            def notification_NodeProtocolInfo(nodeId, byte, value) 
                puts 'TODO'
            end
                
            # One of the node names has changed (name, manufacturer, product).
            def notification_NodeNaming(nodeId, byte, value) 
                ptus 'TODO'
            end
                
            # A node has triggered an event.  This is commonly caused when a node 
            # sends a Basic_Set command to the controller.  The event value is 
            # stored in the notification.
            def notification_NodeEvent(nodeId, byte, value) 
                puts 'TODO'
            end
                
            # Polling of a node has been successfully turned off by a call 
            # to Manager::DisablePoll
            def notification_PollingDisabled(nodeId, byte, value) 
                puts 'TODO'    
            end
                
            # Polling of a node has been successfully turned on by a call 
            # to Manager::EnablePoll
            def notification_PollingEnabled(nodeId, byte, value) 
                puts 'TODO'
            end
                
            # A driver for a PC Z-Wave controller has been added and is ready 
            # to use.  The notification will contain the controller's Home ID, 
            # which is needed to call most of the Manager methods.
            def notification_DriverReady(nodeId, byte, value) 
                puts 'TODO'
            end
                
            # Driver failed to load */
            def notification_DriverFailed(nodeId, byte, value) 
                puts 'TODO'
            end
                
            # All nodes and values for this driver have been removed.  
            # This is sent instead of potentially hundreds of individual node 
            # and value notifications.
            def notification_DriverReset(nodeId, byte, value) 
                puts 'TODO'
            end
                
            # The last message that was sent is now complete.
            def notification_MsgComplete(nodeId, byte, value) 
                puts 'TODO'
            end
                
            # The queries on a node that are essential to its operation have 
            # been completed. The node can now handle incoming messages.
            def notification_EssentialNodeQueriesComplete(nodeId, byte, value) 
                puts "==> marking node #{nodeId} as refreshed"
                #OpenZWave::RefreshedNodes[nodeId] = true
            end
                
            # All the initialisation queries on a node have been completed.
            def notification_NodeQueriesComplete(nodeId, byte, value)
                # node monitor phase 2:
                @ValueMonitorMutex.synchronize do
                    sleep(2)
                    AnsibleValue[:_nodeId => nodeId].each { |val|    
                        val.get()
                    }
                    # all values now should be fresh
                    @ValueMonitors[nodeId] = false
                    fire_callback(:onMonitorStop)
                    puts "==> trigger change monitor ENDED<=="
                end
            end
                
            # All awake nodes have been queried, so client application can 
            # expected complete data for these nodes.
            def notification_AwakeNodesQueried(nodeId, byte, value) 
                puts 'TODO'
            end
                        
            # All nodes have been queried, so client application can 
            # expect complete data. 
            def notification_AllNodesQueried(nodeId, byte, value) #
                puts 'TODO'
            end 
            
            # ------------------------------
            # CONTROLLER STATE NOTIFICATIONS
            # ------------------------------
            
            # handle controller state notifications
            def controller_state(idx)
                puts OpenZWave::ControllerStates[idx].join(': ')
            end
=begin
ControllerCommand_RemoveFailedNode (id=7)
irb(main):024:0> ZWT.manager.BeginControllerCommand(HomeID, 7, false, 3, 0)
=> true
irb(main):025:0> 
------ ZWAVE MESSAGE (2012-02-05 22:43:28 +0200) ------
ControllerState_InProgress: The controller is communicating with the other device to carry out the command.

------ ZWAVE MESSAGE (2012-02-05 22:43:28 +0200) ------
ControllerState_Completed: The command has completed successfully.
=end
    # TODO: remove all AnsibleValues upon completion of 
    
    
            #
            # Zwave value notification system only informs us about a _manual_
            # operation of a ZWave node using a ValueChanged notification.
            # We need to monitor that node in order to get the actual device status. 
            def trigger_value_monitor(nodeId) 
                @ValueMonitorMutex.synchronize do
                    # define a node monitor proc then spawn a new thread to run it
                    unless @ValueMonitors[nodeId] then
                        puts "==> spawning trigger change monitor thread for #{nodeId}<=="
                        fire_callback(:onMonitorStart)
                        AnsibleValue[:_nodeId => nodeId].each { |val|
                            manager_send(:RefreshValue, val)
                        }
                        # node monitor phase 1: request all dynamic node values from OZW
                        #manager_send(:RequestNodeDynamic, Ansible::ZWave::HomeID, nodeId)
                        # then declare the handler to run upon NodeQueriesComplete notification
                        @ValueMonitors[nodeId] = true
                        # node monitor phase 2: see notification_NodeQueriesComplete
                    end # unless 
                end # do
            end
            
        end #class
    
    end

end # module Ansible