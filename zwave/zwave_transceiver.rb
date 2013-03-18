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
                # handler for both connection_[closed|died]
                @connFailureHandler = Proc.new  { |client, con|
                    @stomp_ok = false
                    puts "STOMP connection failed!!! sleeping for 3 seconds and then retrying..."
                    puts "stack trace: \n\t"<< caller.join("\t\n")
                    sleep(3)
                    @stompserver.connect
                }
            end
            
            def init_stomp
                unless @stomp_ok 
                    begin
                        # initialize connection to STOMP server
                        @stompserver = OnStomp::Client.new(@stompURL)
                        @stompserver.on_connection_died  &@connFailureHandler
                        @stompserver.on_connection_closed &@connFailureHandler
                        @stompserver.on_connection_established { |client, con|
                            puts "STOMP: Connected to broker using protocol version #{con.version}"
                            @stomp_ok = true
                        }
                        @stompserver.connect
                    rescue Errno::ECONNREFUSED => e
                        @stomp_ok = false
                        dump_trace(e, "STOMP", "init_stomp")
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
                            puts "Connecting to Thrift server at #{host}:#{port}"
                            @thrift_transport = Thrift::BufferedTransport.new(Thrift::Socket.new(host, port))
                            @thrift_protocol = Thrift::BinaryProtocol.new(@thrift_transport)
                            @thrift_transport.open()
                            @manager = ::OpenZWave::RemoteManager::Client.new(@thrift_protocol)
                            @thrift_ok = true
                            # the heartbeat thread sends a controller node query every 10 seconds 
                            @thrift_heartbeat = thriftHeartbeat(10)
                            # fetch all known ValueID's from the server
                            @manager.SendAllValues
                        else
                            raise "Thrift URL invalid"
                        end
                    rescue Exception => e
                        @thrift_ok = false
                        dump_trace(e, "THRIFT", "init_thrift")
                    end
                end
              return @manager
            end
            
            def thriftHeartbeat(period)
                return Thread.new {
                    puts "Thrift: New heartbeat thread, #{Thread.current}"
                    while (@thrift_ok) do
                        sleep(period)
                        @thriftMutex.synchronize {
                            begin
                              @manager.ping()  
                            rescue Exception => e
                              dump_trace("Thrift heartbeat", e, "ping")
                              @thrift_ok = false
                            end
                        }
                    end
                    puts "Thrift: heartbeat thread exiting, #{Thread.current}"
                }
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
                        # mark connection as not OK so as to reconnect at next call
                        @thrift_ok = false
                        dump_trace(e, "Thrift transport exception", meth.inspect)
                        sleep(1)
                        retry
                     rescue Exception => e
                        dump_trace(e, "Other exception", meth.inspect)
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
                        value = getValueFrom(msg)
                    rescue Exception => e
                        dump_trace("ZWaveTransceiver",e, "decode_monitor")
                    end
                end
                # 2) Sleep forever (how pretty)
                while true #@alive #FIXME
                    sleep(1)
                end
            end
            
            #
            # parse STOMP message for useful HomeID and ValueID headers
            #
            def getValueFrom(msg)
                value = nil
                # lookup or create ValueID related to Notification
                if msg.headers["HomeID"] and msg.headers["ValueID"] then 
                    homeID = msg.headers["HomeID"]
                    valueID = msg.headers["ValueID"]
                    # sync current HomeID
                    h = homeID.to_i(16)
                    if Ansible::ZWave.const_defined?(:HomeID) then
                        raise "HomeID changed from 0x#{Ansible::ZWave::HomeID.to_s(16)} to #{homeID}" unless h == Ansible::ZWave::HomeID
		    else 
			# ZWave homeID not yet set
			if h > 0 then
				puts "------ SETTING HOME ID: #{homeID}"
				Ansible::ZWave.const_set("HomeID", h) 
			else
				raise "HomeID not set by controller - This shouldn't happen since all controllers come with the HomeID set in firmware"
			end
		    end
                    # get or create ValueID object
                    value = Ansible::ZWave::ValueID.get_or_create(homeID, valueID)
                end
                doNotifications(msg,value)
                doControllerState(msg)
                return value
            end

            #
            # process value notifications in STOMP message,
            # also firing any notification-related callbacks bound to this ValueID
            #
            def doNotifications(msg,value)
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
            end

            #
            # process controller state+error notifications in STOMP message,
            # also firing any controller state+error callbacks
            #
            def doControllerState(msg)
                # controller state and error change notification mechanism
                %w{ControllerState ControllerError}.each { | key |
                    if (data = msg.headers[key]) and (idx = data.to_i(16)) then
                        puts eval("OpenZWave::#{key}s[idx].join(': ')")
                        fire_callback("on#{key}".to_sym, idx)
                    end                    
                }
            end
            
            #
            #
            # NOTIFICATIONS
            #
            
            # a value has been added to the Z-Wave network
            def notification_ValueAdded(nodeId, byte, value); end            
            
            # A node value has been removed from OpenZWave's list.  
            # This only occurs when a node is removed.
            def notification_ValueRemoved(nodeId, byte, value); end
                
            #  A node value has been updated from the Z-Wave network.            
            def notification_ValueChanged(nodeId, byte, value)
              # node monitor phase 2:
              #if value.get 
              @ValueMonitorMutex.synchronize {
                  sleep(2)
                  AnsibleValue[:_nodeId => nodeId].each { |val|    
                      val.get()
                  }
                  # all values now should be fresh
                  @ValueMonitors[nodeId] = false
                  fire_callback(:onMonitorStop)
                  puts "==> trigger change monitor ENDED<=="
              }
            end
            
            #  A node value has been refreshed from the Z-Wave network.
            def notification_ValueRefreshed(nodeId, byte, value); end 
                #value.get unless value.nil?
            
            # The associations for the node have changed. The application 
            # should rebuild any group information it holds about the node.
            def notification_Group(nodeId, byte, value); end 
                        
            # A new node has been found (not already stored in zwcfg*.xml file)
            def notification_NodeNew(nodeId, byte, value); end
                        
            # A new node has been added to OpenZWave's list.  This may be due 
            # to a device being added to the Z-Wave network, or because the 
            # application is initializing itself.
            def notification_NodeAdded(nodeId, byte, value); end 
                
            # A node has been removed from OpenZWave's list.  This may be due 
            # to a device being removed from the Z-Wave network, or because 
            # the application is closing.
            def notification_NodeRemoved(nodeId, byte, value); end 

            # Basic node information has been receievd, such as whether 
            # the node is a listening device, a routing device and its 
            # baud rate and basic, generic and specific types. It is 
            # after this notification that you can call Manager::GetNodeType 
            # to obtain a label containing the device description. */            
            def notification_NodeProtocolInfo(nodeId, byte, value); end
                
            # One of the node names has changed (name, manufacturer, product).
            def notification_NodeNaming(nodeId, byte, value); end 
                
            # A node has triggered an event.  This is commonly caused when a node 
            # sends a Basic_Set command to the controller.  The event value is 
            # stored in the notification.
            def notification_NodeEvent(nodeId, byte, value) 
              # OpenZWave peculiarity: we eventually got a ValueChanged event, but the value
              # reported by OpenZWave is unchanged. Thus we need to poll the
              # device using :RequestNodeDynamic, wait for NodeQueriesComplete
              # then re-get the value
              trigger_node_monitor(nodeId)
            end
                
            # Polling of a node has been successfully turned off by a call 
            # to Manager::DisablePoll
            def notification_PollingDisabled(nodeId, byte, value); end 
                
            # Polling of a node has been successfully turned on by a call 
            # to Manager::EnablePoll
            def notification_PollingEnabled(nodeId, byte, value); end 
                
            # A driver for a PC Z-Wave controller has been added and is ready 
            # to use.  The notification will contain the controller's Home ID, 
            # which is needed to call most of the Manager methods.
            def notification_DriverReady(nodeId, byte, value); end 
                
            # Driver failed to load */
            def notification_DriverFailed(nodeId, byte, value); end 
                
            # All nodes and values for this driver have been removed.  
            # This is sent instead of potentially hundreds of individual node 
            # and value notifications.
            def notification_DriverReset(nodeId, byte, value); end
                
            # The last message that was sent is now complete.
            def notification_MsgComplete(nodeId, byte, value); end
                
            # The queries on a node that are essential to its operation have 
            # been completed. The node can now handle incoming messages.
            def notification_EssentialNodeQueriesComplete(nodeId, byte, value); end 
                #OpenZWave::RefreshedNodes[nodeId] = true
                
            # All the initialisation queries on a node have been completed.
            def notification_NodeQueriesComplete(nodeId, byte, value); end
                
            # All awake nodes have been queried, so client application can 
            # expected complete data for these nodes.
            def notification_AwakeNodesQueried(nodeId, byte, value); end 
                        
            # All nodes have been queried, so client application can 
            # expect complete data. 
            def notification_AllNodesQueried(nodeId, byte, value); end
            
            # ------------------------------
            # CONTROLLER STATE NOTIFICATIONS
            # ------------------------------
            
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
    

                
            # Zwave value notification system only informs us about a _manual_
            # operation of a ZWave node using a ValueChanged notification.
            # We need to monitor that node in order to get the actual device status. 
            # Sequence of events:
=begin          
  notification_NodeEvent (n:3) (b:255) ()
            (calls trigger_value_monitor)
  notification_ValueChanged (n:3) (b:0) (ZWaveValue[n:3 g:1 cc:38 i:1 vi:0 t:1]==94(Fixnum))
  notification_NodeQueriesComplete (n:3) (b:0) ()

=end

            def trigger_node_monitor(nodeId) 
                @ValueMonitorMutex.synchronize {
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
                }
            end #def
    
        end #class
    
    end # module ZWave

end # module Ansible

