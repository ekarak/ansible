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

GC::Profiler.enable
Thread.new {
    while(true) do
        sleep(600)
        GC.start
        puts '--- GC Profiler report:'
        puts GC::Profiler.report
    end
}

$:.push(Dir.getwd)
$:.push(File.join(Dir.getwd, 'knx'))
$:.push(File.join(Dir.getwd, 'zwave'))
$:.push(File.join(Dir.getwd, 'devices'))

require 'transceiver'
require 'zwave_transceiver'
require 'zwave_command_classes'

require 'knx_transceiver'
require 'knx_tools'
require 'knx_value'

require 'ansible_device'

require 'config'
#

include Ansible
include Ansible::ZWave
include Ansible::KNX

begin
    
    ZWT = ZWave::ZWave_Transceiver.new(STOMP_URL, THRIFT_URL)
    ZWT.manager.SendAllValues
    sleep(2)
    
    ZWSwitch = AnsibleValue[ 
        :_nodeId => 2,  
        :_genre => OpenZWave::RemoteValueGenre::ValueGenre_Basic][0]
    ZWDimmer = AnsibleValue[ 
         :_nodeId => 5,  
         :_genre => OpenZWave::RemoteValueGenre::ValueGenre_User,
         :_commandClassId => 38, #SWITCH_MULTILEVEL
         :_valueIndex => 0][0]
         
    ZWKouzina = AnsibleValue[ 
        :_nodeId => 6,  
        :_genre => OpenZWave::RemoteValueGenre::ValueGenre_User]
    
    #KNX = Ansible::KNX::KNX_Transceiver.new("ip:192.168.0.10")
    KNX = KNX::KNX_Transceiver.new(KNX_URL)
    
    # map my ACT HomePro Appliance module to KNX
    SWITCH = Switch.new(
        :master_control => ZWSwitch,
        :switch         => KNXValue.new("1.001", "1/0/20"),
        :switch_status  => KNXValue.new("1.001", "1/0/21") 
        ) if ZWSwitch
    
    # map my ACT HomePro Lamp module to KNX
    DIMMER = Dimmer.new(
        :master_control => ZWDimmer,
        :switch         => KNXValue.new("1.001", "1/0/40"), 
        :switch_status  => KNXValue.new("1.001", "1/0/41"),
        :dimming        => KNXValue.new('5.001', "1/0/42"), 
        :dimming_status => KNXValue.new('5.001', "1/0/43"),
        :scene          => KNXValue.new('18.001', "1/0/44")
    )
    
    # map my garden lights to ZWave
    GARDEN = Switch.new(
        :master_control => KNXValue.new("1.001", "1/0/1"),
        :switch         => ZWSwitch
        ) if ZWSwitch
    
    KOUZINA1 = Switch.new(
        :master_control => ZWKouzina[0],
        :switch         => KNXValue.new("1.001", "1/0/60"),
        :switch_status  => KNXValue.new("1.001", "1/0/61")
    )
    
    KOUZINA2 = Switch.new(
        :master_control => ZWKouzina[1],
        :switch         => KNXValue.new("1.001", "1/0/62"),
        #:switch         => KNXValue.new("1.001", "5/0/2"), # fancy radar
        :switch_status  => KNXValue.new("1.001", "1/0/63")
    )

rescue Exception => e
    puts e.to_s+"\n\t"+e.backtrace.join("\n\t")
end
=begin
knx1_0_20.add_callback(:onUpdate) { |sender, cb, args| 
    puts "KNX value 1/0/20 updated! args=#{args}"
    zwval = sender.current_value == 0 ? 0 : 1
    Switch.set(zwval) # FIXME convert value domains
}
Switch.add_callback(:onUpdate) { | sender, cb, args|
    puts "ZWave Switch  HAS CHANGED #{args}"
    knxval = sender.current_value == 0 ? 0 : 1
    KNX.send_apdu_raw(str2addr("1/0/21"), [0, 0x80 | knxval])
}

Ansible::KNX::KNXValue.new('1.001', "1/0/40") ).add_callback(:onUpdate) { |sender, cb, args| 
    puts "KNX value 1/0/40 updated! args=#{args}"
    zwval = sender.current_value == 0 ? 0 : 99
    Dimmer.set(zwval) # FIXME convert value domains
}
Dimmer.add_callback(:onUpdate) { | sender, cb, args|
    puts "ZWave DimerOnOff HAS CHANGED #{args}"
    knxval = sender.current_value == 0 ? 0 : 1
    KNX.send_apdu_raw(str2addr("1/0/41"), [0, 0x80 | knxval])
}

Ansible::KNX::KNXValue.new('5.001', "1/0/42") ).add_callback(:onUpdate) { |sender, cb, args| 
    puts "KNX value 1/0/42 updated! args=#{args}"
    zwval = sender.current_value * 99 / 255 
    DimmerAbsolute.set(zwval.round) # FIXME convert value domains
}
DimmerAbsolute.add_callback(:onUpdate) { | sender, cb, args|
    puts "ZWave DimmerAbsolute HAS CHANGED #{args}"
    knxval = sender.current_value * 255 / 99 
    KNX.send_apdu_raw(str2addr("1/0/43"), [0, 0x80,  knxval.round]) ## NOTICE apdu
}
=end
