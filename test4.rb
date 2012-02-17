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

require 'transceiver'

require 'knx_transceiver'
require 'knx_tools'
require 'knx_value'
require 'config'

# a lone KNX transceiver will log all KNX activity by default
KNX = Ansible::KNX::KNX_Transceiver.new(Ansible::KNX_URL)
#V1 = Ansible::KNX::KNXValue.new("1.001", "1/0/20")
V1 = Ansible::KNX::KNXValue.new("1.005", "5/0/1")
V2 = Ansible::KNX::KNXValue.new("1.005", "5/0/2")

V3 = Ansible::KNX::KNXValue.new("1.001", "1/1/0")
V3.description = "Basement light"

V4 = Ansible::KNX::KNXValue.new("1.001", "3/0/3")
V4.description = "Anakykloforia ZNX"

V5 = Ansible::KNX::KNXValue.new("5.004", "1/0/42")

#BasementLights = 

