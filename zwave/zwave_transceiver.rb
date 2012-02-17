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
        
    class ZWave_Transceiver < Transceiver
                
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
                            name = md[1][0].downcase + md[1][1..-1]
                            puts "Notification: #{name} (n:#{node}) (b:#{byte}) (v:#{value})"
                            __send__("notification_"+name, node, byte, value)
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
                
        def notification_valueAdded(nodeId, byte, value)
                #@@Values[homeID].push(value)
        end
        
        def notification_valueRemoved(nodeId, byte, value)            
                #  A node value has been removed from OpenZWave's list.  This only occurs when a node is removed. 
                #@@Values[homeID].delete(value)
        end
                        
        def notification_valueChanged(nodeId, byte, value) 
            #  A node value has been updated from the Z-Wave network. */
            # notify the value
            value.fire_callback(:onValueChanged)
            unless Ansible::ZWave::RefreshedNodes[nodeId]  then
                #ZWave peculiarity: we got a ValueChanged event, but the value
                # reported by OpenZWave is unchanged. Thus we need to poll the
                # device using :RequestNodeDynamic, wait for NodeQueriesComplete
                # then re-get the value
                #value.trigger_change_monitor
            end
        end
        
        def notification_valueRefreshed(nodeId, byte, value) 
            puts "Value #{value} refreshed!!!"
        end
        
        def notification_group(nodeId, byte, value) 
            # The associations for the node have changed. The application should rebuild any group information it holds about the node. */
        end
                    
        def notification_nodeNew(nodeId, byte, value) 
            # A new node has been found (not already stored in zwcfg*.xml file) */
        end
                    
        def notification_nodeAdded(nodeId, byte, value) 
            # A new node has been added to OpenZWave's list.  This may be due to a device being added to the Z-Wave network, or because the application is initializing itself. */
        end
                    
        def notification_nodeRemoved(nodeId, byte, value) 
            # A node has been removed from OpenZWave's list.  This may be due to a device being removed from the Z-Wave network, or because the application is closing. */
        end
                    
        def notification_nodeProtocolInfo(nodeId, byte, value) 
            # Basic node information has been receievd, such as whether the node is a listening device, a routing device and its baud rate and basic, generic and specific types. It is after this notification that you can call Manager::GetNodeType to obtain a label containing the device description. */
        end
                    
        def notification_nodeNaming(nodeId, byte, value) 
            # One of the node names has changed (name, manufacturer, product). */
        end
                    
        def notification_nodeEvent(nodeId, byte, value) 
            # A node has triggered an event.  This is commonly caused when a node sends a Basic_Set command to the controller.  The event value is stored in the notification. */
        end
                    
        def notification_pollingDisabled(nodeId, byte, value) 
            # Polling of a node has been successfully turned off by a call to Manager::DisablePoll */
        end
                    
        def notification_pollingEnabled(nodeId, byte, value) 
            # Polling of a node has been successfully turned on by a call to Manager::EnablePoll */
        end
                    
        def notification_driverReady(nodeId, byte, value) 
            # A driver for a PC Z-Wave controller has been added and is ready to use.  The notification will contain the controller's Home ID, which is needed to call most of the Manager methods. */
        end
                    
        def notification_driverFailed(nodeId, byte, value) 
            # Driver failed to load */
        end
                    
        def notification_driverReset(nodeId, byte, value) 
            # All nodes and values for this driver have been removed.  This is sent instead of potentially hundreds of individual node and value notifications. */
        end
                    
        def notification_msgComplete(nodeId, byte, value) 
            # The last message that was sent is now complete. */
        end
                    
        def notification_essentialNodeQueriesComplete(nodeId, byte, value) 
            # The queries on a node that are essential to its operation have been completed. The node can now handle incoming messages. */
            puts "==> marking node #{nodeId} as refreshed"
            #OpenZWave::RefreshedNodes[nodeId] = true
        end
                    
        def notification_nodeQueriesComplete(nodeId, byte, value) 
            # All the initialisation queries on a node have been completed. */
            Ansible::ZWave::RefreshedNodes[nodeId] = true
            Thread.new {
                hash = {}
                hash[:_nodeId] = nodeId
                unless value.nil? then hash[:_genre] = value._genre end 
                # reget all values of the same genre for this node
                AnsibleValue[hash].each { |val|
                    puts "==> re-getting value #{val}"
                    val.get()
                }
                #sleep(3)   # give me 3 secs to get the values!!!
                Ansible::ZWave::RefreshedNodes[nodeId] = false
            }
        end
                    
        def notification_awakeNodesQueried(nodeId, byte, value) 
            # All awake nodes have been queried, so client application can expected complete data for these nodes. */
            puts 'Notification: AwakeNodeQueried'
        end
                    
        def notification_allNodesQueried(nodeId, byte, value) #
            #
        end 
        
        # ----------
        
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

    end #class
    
end

end # module Ansible