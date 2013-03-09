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

#
# global configuration options file
#

module Ansible
        
    # STOMP Server URL
    STOMP_URL = 'stomp://localhost'
    
    #
    # KNX subsystem configuration
    #
    module KNX
        
        # KNX eibd server URL (not the actual KNX interface URL!)
        KNX_URL = "local:/tmp/eib"
        #KNX_URL = "ip:localhost"
        
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
    end
    
    #
    # ZWave sybsustem configuration
    #    
    module ZWave
        
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

        #################        
        # OpenZWave Thrift Server URL
        THRIFT_URL = 'thrift://localhost'
        #THRIFT_URL = 'thrift://192.168.0.100'

        ThriftPort = 9090

    end
    
end

#

module OpenZWave
    
    # path to OpenZWave source
    OZW_SRC = "/home/ekarak/ozw/open-zwave-read-only/cpp/src"
    
    # include Thrift RemoteManager interface files
    $:.push("/home/ekarak/ozw/Thrift4OZW/gen-rb")

end

# from  http://snippets.dzone.com/posts/show/2785
module Kernel
private
    def this_method_name
      caller[0] =~ /`([^']*)'/ and $1
    end
end
