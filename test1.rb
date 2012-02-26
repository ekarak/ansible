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

require 'config'
require 'transceiver'
require 'zwave_transceiver'
require 'zwave_command_classes'
require 'zwave_value'

include Ansible

ZWT = ZWave::ZWave_Transceiver.new(Ansible::STOMP_URL, Ansible::ZWave::THRIFT_URL)
ZWT.manager.SendAllValues
sleep(3)

S = AnsibleValue[:_nodeId => 2, :_genre => 1]
D = AnsibleValue[:_nodeId => 5, :_genre => 1]
K = AnsibleValue[:_nodeId => 6, :_genre => 1]

=begin
Tree = AnsibleValue[ 
    :_nodeId => 2, 
    :_genre => OpenZWave::RemoteValueGenre::ValueGenre_Basic
    ][0]

Tree.add_callback(:onUpdate) { | val, event|
    puts "-------- ZWAVE NODE #{val._nodeId} #{event}! CURRENT VALUE==#{val.current_value} ------------"
}

if Dimmer = AnsibleValue[ 
    :_nodeId => 5,
    :_type => OpenZWave::RemoteValueType::ValueType_Byte,
    :_genre => OpenZWave::RemoteValueGenre::ValueGenre_Basic
    ] then
    Dimmer[0].add_callback(:onUpdate) { | val, event|
        puts "-------- ZWAVE NODE  #{val._nodeId} #{event}! CURRENT VALUE==#{val.current_value} ------------"
#        Tree.set(val.current_value>0)
    }
else
    puts "valueid not found!"
end
    
=end
