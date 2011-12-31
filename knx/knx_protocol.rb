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

require 'rubygems'
require 'bit-struct'

class KNX_TP_ControlField < BitStruct
    unsigned    :lpdu_code, 2,     "LPDU (2bit) 2=L_DATA.req 3=L_Poll_data.req"
    unsigned    :rep_flag,    1,     "Repeat flag"
    unsigned    :ack_not,    1,     "0 = Acknowledge frame, 1 = standard frame"
    unsigned    :prio_class, 2,     "Priority class (0=highest .. 3=lowest)"
    unsigned    :unused1,   2,      "two unused bits (should be 00)"
end

class KNX_L_DATA_Frame < BitStruct
    # octet 0: TP1 control field
    unsigned    :lpdu_code, 2,     "LPDU (2bit) 2=L_DATA.req 3=L_Poll_data.req"
    unsigned    :rep_flag,    1,     "Repeat flag"
    unsigned    :ack_not,    1,     "0 = Acknowledge frame, 1 = standard frame"
    unsigned    :prio_class, 2,     "Priority class (0=highest .. 3=lowest)"
    unsigned    :unused1,   2,      "two unused bits (should be 00)"
    # octet 1+2: source
    unsigned    :src_addr,  16, "Source Address"
    # octet 3+4: destination
    unsigned    :dst_addr,  16, "Destination Address"
    # octet 5: control fields
    unsigned    :daf,       1,  "Dest.Address flag 0=physical 1=group"
    unsigned    :ctrlfield, 3,  "Network control field"
    unsigned    :datalength,    4,  "Data length (bytes after octet #6)"
    # octet 6 .. plus 2 bits from octet 7: TPCI+APCI
    unsigned    :tpci,  2,  "TPCI control bits 8+7"
    unsigned    :seq,   4,  "Packet sequence"
    unsigned    :apci,    4,  "APCI control bits"
    # octet 7 ... end
    unsigned    :apci_data, 6, "APCI/Data combined"
    rest            :data,            "rest of frame"
end

#########################################################

APCICODES = "A_GroupValue_Read A_GroupValue_Response A_GroupValue_Write \
        A_PhysicalAddress_Write A_PhysicalAddress_Read A_PhysicalAddress_Response \
        A_ADC_Read A_ADC_Response A_Memory_Read A_Memory_Response A_Memory_Write \
        A_UserMemory A_DeviceDescriptor_Read A_DeviceDescriptor_Response A_Restart \
        A_OTHER".split()

TPDUCODES = "T_DATA_XXX_REQ T_DATA_CONNECTED_REQ T_DISCONNECT_REQ T_ACK".split()

PRIOCLASSES = "system alarm high low".split()

#########################################################


#~ data = [188, 17, 200, 18, 1, 242, 0, 128, 80, 171] .pack("c*")
#~ knxpacket = KNX_L_DATA_Frame.new(data)
#~ knxpacket.fields.each { |a|
    #~ puts "#{a.name} == #{a.inspect_in_object(knxpacket, :default)}"
#~ }
#puts knxpacket.inspect_detailed
#~ require 'knx_tools'
#puts addr2str(knxpacket.src_addr)