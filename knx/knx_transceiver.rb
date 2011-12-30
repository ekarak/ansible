#~ Project Ansible
#~ (c) 2011 Elias Karakoulakis <elias.karakoulakis@gmail.com>

require 'cgi'

require 'transceiver'
require 'EIBConnection'

require 'knx_protocol'
require 'knx_tools'

###################
# KNX MONITOR TOPIC: 
#   passes all KNX activity to STOMP
#   KNX frame headers as defined in knx_protocol.rb
KNX_MONITOR_TOPIC = "/queue/knx/monitor"

#################
# KNX COMMAND_TOPIC
#   header "dest_addr" => KNX destination address (group/phys) in 16-bit unsigned integer format i.e. "1024" meaning "1/0/0" in 3-level fmt
#   body => the raw APDU for transmission (command flags+data) in Marshal.dump(CGI.escape()) format
KNX_COMMAND_TOPIC = "/queue/knx/command"

class KNX_Transceiver < Transceiver

    attr_reader :stomp
    
    def initialize(connURL)
        puts("KNX: init connection to #{connURL}")
        @monitor_conn = EIBConnection.new()
        @monitor_conn.EIBSocketURL(connURL)
        @send_conn = EIBConnection.new()
        @send_conn.EIBSocketURL(connURL)
        @knxbuf = EIBBuffer.new()
        super(connURL)
    end
    
    def run()
        puts("KNX Transceiver thread is running!")
        begin
            #### part 1: connect to STOMP broker
            @stomp = OnStomp.connect "stomp://localhost"
            #### part 2: subscribe to command channel, listen for messages and pass them to KNX
            @stomp.subscribe KNX_COMMAND_TOPIC do |msg|
                dest = msg.headers['dest_addr'].to_i
                #TODO: check address limits
                apdu = Marshal.load(CGI.unescape(msg.body))
                send_apdu_raw(dest, apdu)
            end
            ##### part 3: monitor KNX bus, post all activity to /knx/monitor
            vbm = @monitor_conn.EIBOpenVBusmonitor()
            loop do
                len = @monitor_conn.EIBGetBusmonitorPacket(@knxbuf)
                @monitor_conn.EIBGetGroup_Src(@buf, src, dest)
                frame = KNX_L_DATA_Frame.new(@knxbuf.buffer.pack('c*'))
                headers = {}
                frame.fields.each { |fld|
                    headers[fld.name] = CGI.escape(fld.inspect_in_object(frame, :default))
                }
                message = "KNX transceiver: #{APCICODES[headers.apci]} packet from #{addr2str(frame.src_addr)} to #{addr2str(frame.dst_addr, frame.daf)}, priority:#{PRIOCLASSES[headers.prio]}"
                @stomp.send(KNX_MONITOR_TOPIC, message, headers)
            end
        rescue NormalExit => e
            puts("KNX transceiver terminating gracefully...")
        rescue Exception => e
            puts("Exception in KNX server thread: #{e}")
            puts("backtrace:\n  " << e.backtrace.join("\n  "))
        ensure
            @conn.EIBClose()
            @stomp.disconnect
        end
    end #def Thread.run()

    def send_apdu_raw(dest, apdu)
        puts("KNX transceiver: sending to group address #{dest}, #{apdu.inspect}")
        if (@send_conn.EIBOpenT_Group(dest, 1) == -1) then
            raise("KNX client: error setting socket mode")
        end
        @send_conn.EIBSendAPDU(apdu)
        @send_conn.EIBReset()
    end
            
end #class 

k = KNX_Transceiver.new("ip:192.168.0.10")
k.thread.join
