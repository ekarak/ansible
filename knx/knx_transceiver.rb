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

require 'cgi'

require 'config'
require 'transceiver'
require 'EIBConnection'
require 'ansible_callback'
require 'knx_protocol'
require 'knx_value'
require 'knx_tools'

module Ansible

    module KNX
        
        #
        # The KNX Transceiver is an object responsible for i/o with the KNX bus. 
        # It does so using eibd, part of BCU-SDK the open-source libary for KNX. 
        class KNX_Transceiver < Transceiver
            include AnsibleCallback
            
            
            # a special exception to break the knx tranceiver loop
            class NormalExit < Exception; end
                
            attr_reader :stomp
            
            
            # initialize a KNXTranceiver
            #
            # *params:
            #   [connURL] an eibd connection URL. see eibd --help for acceptable values
            def initialize(connURL=KNX_URL)
                raise "Already initialized!" unless  Ansible::KNX::KNXValue.transceiver.nil?
                @connURL = connURL
                @monitor_conn_ok, @send_conn_ok = false, false
                @send_mutex = Mutex.new()
                @knxbuf = EIBBuffer.new()
                #
                super()
                # store reference to ourselves to the classes that use us
                Ansible::KNX::KNXValue.transceiver = self
                # register default handler for KNX frames
                add_default_callback
            end
            
            # the default callback to be called on each KNX telegram.
            # Needless to say this proc shouldn't take much long...            
            def add_default_callback
                add_callback(:onKNXtelegram) { | sender, cb, frame|
                    puts(frame_inspect(frame)) if $DEBUG
                    case frame.apci.value
                    when 0 then # A_GroupValue_Read
                        puts "read request for knx address #{addr2str(frame.dst_addr, frame.daf)}"
                        AnsibleValue[:groups => [frame.dst_addr]].each { |v|
                            unless v.current_value.nil? then
                                puts "==> responding with value #{v}"
                                send_apdu_raw(frame.dst_addr, v.to_apdu(0x40))
                            end
                        }
                    when 1..2 then # A_GroupValue_Response, A_GroupValue_Write
                        puts "response frame by #{addr2str(frame.src_addr)} for knx address #{addr2str(frame.dst_addr, frame.daf)}"
                        AnsibleValue[:groups => [frame.dst_addr]].each { |v|
                            v.update_from_frame(frame)
                            puts "synchronized knx value #{v} from frame #{frame.inspect}" if $DEBUG
                        }
                    end
                }
            end

            # initialize eibd connection
            def init_eibd(conn_symbol, conn_ok_symbol)
                unless instance_variable_get(conn_ok_symbol)
                    begin
                        puts("KNX: init #{conn_symbol} to #{@connURL}")
                        conn = EIBConnection.new()
                        conn.EIBSocketURL(@connURL)
                        instance_variable_set(conn_symbol, conn)
                        instance_variable_set(conn_ok_symbol, true)
                        return(conn)
                    rescue Errno::ECONNRESET => e
                        conn.EIBClose
                        instance_variable_set(conn_ok_symbol, false)
                        puts "init_eibd: Disconnected, retrying in 10 seconds..."
                        sleep(10)
                    end
                end
            end
            
            # get handle to eibd monitor connection
            def eibd_connection(conn_symbol, conn_ok_symbol)
                if instance_variable_get(conn_ok_symbol) then
                    return(instance_variable_get(conn_symbol))
                else
                    init_eibd(conn_symbol, conn_ok_symbol)
                end
            end

            # get handle to KNX monitoring connection, reconnecting if necessary
            def monitor_conn; return(eibd_connection(:@monitor_conn, :@monitor_conn_ok)); end
               
            # get handle to KNX sending connection, reconnecting if necessary
            def send_conn; return(eibd_connection(:@send_conn, :@send_conn_ok)); end
                
            # the main KNX transceiver thread
            def run()
                puts("KNX Transceiver thread is running!")
                @stomp = nil
                begin
                    #### part 1: connect to STOMP broker
                    @stomp = OnStomp.connect(STOMP_URL)
                    #### part 2: subscribe to command channel, listen for messages and pass them to KNX
                    # @stomp.subscribe KNX_COMMAND_TOPIC do |msg|
                        # dest = msg.headers['dest_addr'].to_i
                        # #TODO: check address limits
                        # apdu = Marshal.load(CGI.unescape(msg.body))
                        # send_apdu_raw(dest, apdu)
                    # end
                    ##### part 3: monitor KNX bus, post all activity to /knx/monitor
                    vbm = monitor_conn.EIBOpenVBusmonitor()
                    knx2stomp_monitor
                rescue Errno::ECONNRESET => e
                    @monitor_conn_ok = false
                    puts("EIBD disconnected! retrying in 10 seconds..")
                    sleep(10)
                    retry                    
                rescue NormalExit => e
                    puts("KNX transceiver terminating gracefully...")
                rescue Exception => e
                    dump_trace(e, "KNXTransceiver", "run")
                    sleep(3) 
                    retry
#                ensure
                    #puts "Closing EIB connection..."
                    #@monitor_conn.EIBClose() if @monitor_conn
                    #puts "Closing STOMP connection..."
                    #@stomp.disconnect if @stomp
                end
            end #def run()
        
            def knx2stomp_monitor
                loop do
                    len = monitor_conn.EIBGetBusmonitorPacket(@knxbuf)
                    #puts "knxbuffer=="+@knxbuf.buffer.inspect
                    frame = L_DATA_Frame.read(@knxbuf.buffer.pack('c*'))
                    #puts "frame:\n\t"
                    headers = {}
                    frame.field_names.each { |fieldname|
                        field = frame.send(fieldname)
                        #puts "\t#{fieldname} == #{field.value}"
                        headers[fieldname] = CGI.escape(field.value.to_s)
                    }
                    @stomp.send(KNX_MONITOR_TOPIC, "KNX Activity", headers)
                    #puts Ansible::KNX::APCICODES[frame.apci] + " packet from " + 
                    #  addr2str(frame.src_addr) + " to " + addr2str(frame.dst_addr, frame.daf) + 
                    #  "  priority=" + Ansible::KNX::PRIOCLASSES[frame.prio_class]
                    fire_callback(:onKNXtelegram, frame.dst_addr, frame)
                    # 
                end
            end
            
            # send a raw APDU to the KNX bus.
            #
            # * Arguments: 
            #   [dest]  destination (16-bit integer)
            #   [apdu] raw APDU (binary string)       
            def send_apdu_raw(dest, apdu)
                @send_mutex.synchronize {
                    raise 'apdu must be a byte array!' unless apdu.is_a?Array
                    puts("KNX transceiver: sending to group address #{dest}, #{apdu.inspect}") if $DEBUG
                    if (send_conn.EIBOpenT_Group(dest, 1) == -1) then
                        raise("KNX client: error setting socket mode")
                    end
                    send_conn.EIBSendAPDU(apdu)
                    send_conn.EIBReset()
                }
            end
            
            # (Try to) read a groupaddr from eibd cache.
            #
            # return it if found, otherwise query the bus. In the latter case, 
            # the main receiver thread (in run()) will act on the response.
            #
            # * Arguments: 
            #   [ga]    Fixnum: group address (0-65535)
            #   [cache_only] boolean: when true, do not query the bus   
            def read_eibd_cache(ga, cache_only=false)
                src = EIBAddr.new()
                buf = EIBBuffer.new()
                result = nil
                @send_mutex.synchronize {
                    # query eibd for a cached value
                    if (send_conn.EIB_Cache_Read_Sync(ga, src, buf, 0) == -1) then
                        # value not found in cache
                        puts "groupaddress #{addr2str(ga, true)} not found in cache."
                        unless cache_only then
                            puts ".. requesting value on bus .."
                            if (send_conn.EIBOpenT_Group(ga, 1) == -1) then
                                raise("KNX client: error setting socket mode")
                            end
                            # send a read request to the bus
                            send_conn.EIBSendAPDU([0,0x00])
                        end
                        send_conn.EIBReset()
                    else
                        send_conn.EIBReset()
                        # value found in cache..
                        puts "found in cache, last sender was #{addr2str(src.data)}"
                        result = buf.buffer
                    end
                }
                return result
            end
            
        end #class 

    end #module KNX
    
end #module Ansible

