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

def decode_framedata(data)
    case data
    when Fixnum then "0x"+data.to_s(16).upcase
    when Array then data.collect{|b| "0x"+b.to_s(16).upcase}
    when String then data.unpack('C*').collect{|b| "0x"+b.to_s(16).upcase}
    end
end

KNX = Ansible::KNX::KNX_Transceiver.new("local:/tmp/eib")
KNX.declare_callback(:onKNXtelegram) { | sender, cb, frame |
    puts "#{Time.now}: #{Ansible::KNX::APCICODES[frame.apci]}" + 
        " from #{addr2str(frame.src_addr)} to #{addr2str(frame.dst_addr, frame.daf)}" + 
        " prio=#{Ansible::KNX::PRIOCLASSES[frame.prio_class]}" +
        " data=" + decode_framedata(frame.datalength > 1 ? frame.data : frame.apci_data).inspect +
        " len=#{frame.datalength}"
}
