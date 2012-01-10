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

load 'knx_transceiver.rb'
load 'knx_tools.rb'
load 'knx_value.rb'

KNX = Ansible::KNX::KNX_Transceiver.new("ip:localhost")
KNX.declare_callback(:onKNXtelegram) { | sender, cb, frame |
    puts "#{Time.now}: #{Ansible::KNX::APCICODES[frame.apci]}" + 
        " from #{addr2str(frame.src_addr)} to #{addr2str(frame.dst_addr, frame.daf)}" + 
        " priority=#{Ansible::KNX::PRIOCLASSES[frame.prio_class]}"
}
