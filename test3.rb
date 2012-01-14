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

$:.push(Dir.getwd)
$:.push(File.join(Dir.getwd, 'knx'))
$:.push(File.join(Dir.getwd, 'zwave'))

load 'transceiver.rb'
load 'zwave_transceiver.rb'
load 'zwave_command_classes.rb'

load 'knx_transceiver.rb'
load 'knx_tools.rb'
load 'knx_value.rb'

stomp_url = 'stomp://localhost'
thrift_url = 'thrift://localhost'

ZWT = Ansible::ZWave_Transceiver.new(stomp_url, thrift_url)
ZWT.manager.SendAllValues
sleep(2)

Switch = AnsibleValue[ 
    :_nodeId => 2,  
    :_genre => OpenZWave::RemoteValueGenre::ValueGenre_Basic][0]
Dimmer = AnsibleValue[ 
    :_nodeId => 5,  
    :_genre => OpenZWave::RemoteValueGenre::ValueGenre_Basic][0]    
DimmerAbsolute = AnsibleValue[ 
     :_nodeId => 5,  
     :_genre => OpenZWave::RemoteValueGenre::ValueGenre_User,
     :_commandClassId => 38, #SWITCH_MULTILEVEL
     :_valueIndex => 0][0]
     
#KNX = Ansible::KNX::KNX_Transceiver.new("ip:192.168.0.10")
KNX = Ansible::KNX::KNX_Transceiver.new("local:/tmp/eib")
KNX.declare_callback(:onKNXtelegram) { | sender, cb, frame |
    puts Ansible::KNX::APCICODES[frame.apci] + " packet from " + 
    addr2str(frame.src_addr) + " to " + addr2str(frame.dst_addr, frame.daf) + 
              "  priority=" + Ansible::KNX::PRIOCLASSES[frame.prio_class]
    case frame.apci
    when 0 then # A_GroupValue_Read
        puts "read request for knx address #{addr2str(frame.dst_addr, frame.daf)}"
        AnsibleValue[:groups => [frame.dst_addr]].each { |val| 
            if val.current_value then
                puts "==> responding with  value #{val}"
                KNX.send_apdu_raw(frame.dst_addr, val.to_apdu())
            end
        }
    when 1 then # A_GroupValue_Response
        # puts "response frame"
    when 2  then # A_GroupValue_Write
        AnsibleValue[:groups => [frame.dst_addr]].each { |v| 
            puts "updating knx value #{v} from frame #{frame.inspect}"
            v.update_from_frame(frame) 
        }
    end
}


AnsibleValue.insert( Ansible::KNX::KNXValue_DPT1.new("5/0/2") ).declare_callback(:onUpdate) { |sender, cb, args| 
    puts "KNX value 1/0/20 updated! args=#{args}"
    zwval = sender.current_value == 0 ? 0 : 1
    Switch.set(zwval) # FIXME convert value domains
}
Switch.declare_callback(:onUpdate) { | sender, cb, args|
    puts "ZWave Switch  HAS CHANGED #{args}"
    knxval = sender.current_value == 0 ? 0 : 1
    KNX.send_apdu_raw(str2addr("1/0/21"), [0, 0x80 | knxval])
}


AnsibleValue.insert( Ansible::KNX::KNXValue_DPT1.new("1/0/40") ).declare_callback(:onUpdate) { |sender, cb, args| 
    puts "KNX value 1/0/40 updated! args=#{args}"
    zwval = sender.current_value == 0 ? 0 : 99
    Dimmer.set(zwval) # FIXME convert value domains
}
Dimmer.declare_callback(:onUpdate) { | sender, cb, args|
    puts "ZWave DimerOnOff HAS CHANGED #{args}"
    knxval = sender.current_value == 0 ? 0 : 1
    KNX.send_apdu_raw(str2addr("1/0/41"), [0, 0x80 | knxval])
}

=begin
AnsibleValue.insert( Ansible::KNX::KNXValue_DPT5.new("1/0/42") ).declare_callback(:onUpdate) { |sender, cb, args| 
    puts "KNX value 1/0/42 updated! args=#{args}"
    zwval = sender.current_value * 99 / 255 
    DimmerAbsolute.set(zwval.round) # FIXME convert value domains
}
DimmerAbsolute.declare_callback(:onUpdate) { | sender, cb, args|
    puts "ZWave DimmerAbsolute HAS CHANGED #{args}"
    knxval = sender.current_value * 255 / 99 
    KNX.send_apdu_raw(str2addr("1/0/43"), [0, 0x80,  knxval.round]) ## NOTICE apdu
}
=end
