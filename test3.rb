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
    sleep(60)
    GC.start
    pus '--- GC Profiler report:'
    puts GC::Profiler.report
}

$:.push(Dir.getwd)
$:.push(File.join(Dir.getwd, 'knx'))
$:.push(File.join(Dir.getwd, 'zwave'))

load 'transceiver.rb'
load 'zwave_transceiver.rb'
load 'zwave_command_classes.rb'

load 'knx_transceiver.rb'
load 'knx_tools.rb'
load 'knx_value.rb'

load 'ansible_device.rb'

stomp_url = 'stomp://localhost'
thrift_url = 'thrift://localhost'

include Ansible

ZWT = ZWave_Transceiver.new(stomp_url, thrift_url)
ZWT.manager.SendAllValues
sleep(2)

ZWSwitch = AnsibleValue[ 
    :_nodeId => 2,  
    :_genre => OpenZWave::RemoteValueGenre::ValueGenre_Basic][0]
ZWDimmer = AnsibleValue[ 
    :_nodeId => 5,  
    :_genre => OpenZWave::RemoteValueGenre::ValueGenre_Basic][0]    
ZWDimmerAbsolute = AnsibleValue[ 
     :_nodeId => 5,  
     :_genre => OpenZWave::RemoteValueGenre::ValueGenre_User,
     :_commandClassId => 38, #SWITCH_MULTILEVEL
     :_valueIndex => 0][0]
     
#KNX = Ansible::KNX::KNX_Transceiver.new("ip:192.168.0.10")
KNX = Ansible::KNX::KNX_Transceiver.new("local:/tmp/eib")

KNX_1_0_20 = Ansible::KNX::KNXValue.new("1.001", "1/0/20")
KNX_1_0_21 = Ansible::KNX::KNXValue.new("1.001", "1/0/21")
KNX_1_0_40 = Ansible::KNX::KNXValue.new("1.001", "1/0/40")
KNX_1_0_41 = Ansible::KNX::KNXValue.new("1.001", "1/0/41")
KNX_1_0_42 = Ansible::KNX::KNXValue.new('5.001', "1/0/42")
KNX_1_0_43 = Ansible::KNX::KNXValue.new('5.001', "1/0/43")

SWITCH = AnsibleDevice::Switch.new(ZWSwitch, KNX_1_0_20, KNX_1_0_21)
DIMMER = AnsibleDevice::Dimmer.new(ZWSwitch, KNX_1_0_40, KNX_1_0_41)
DIMMER.bind_dimming(ZWDimmerAbsolute, KNX_1_0_42, KNX_1_0_43)

=begin
knx1_0_20.declare_callback(:onUpdate) { |sender, cb, args| 
    puts "KNX value 1/0/20 updated! args=#{args}"
    zwval = sender.current_value == 0 ? 0 : 1
    Switch.set(zwval) # FIXME convert value domains
}
Switch.declare_callback(:onUpdate) { | sender, cb, args|
    puts "ZWave Switch  HAS CHANGED #{args}"
    knxval = sender.current_value == 0 ? 0 : 1
    KNX.send_apdu_raw(str2addr("1/0/21"), [0, 0x80 | knxval])
}

Ansible::KNX::KNXValue.new('1.001', "1/0/40") ).declare_callback(:onUpdate) { |sender, cb, args| 
    puts "KNX value 1/0/40 updated! args=#{args}"
    zwval = sender.current_value == 0 ? 0 : 99
    Dimmer.set(zwval) # FIXME convert value domains
}
Dimmer.declare_callback(:onUpdate) { | sender, cb, args|
    puts "ZWave DimerOnOff HAS CHANGED #{args}"
    knxval = sender.current_value == 0 ? 0 : 1
    KNX.send_apdu_raw(str2addr("1/0/41"), [0, 0x80 | knxval])
}

Ansible::KNX::KNXValue.new('5.001', "1/0/42") ).declare_callback(:onUpdate) { |sender, cb, args| 
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
