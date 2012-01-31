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
require 'bindata'

module Ansible
    
    module KNX
    
        class TP_ControlField < BinData::Record
            bit2    :lpdu_code, { :display_name => "LPDU (2bit) 2=L_DATA.req 3=L_Poll_data.req" }
            bit1    :rep_flag,  { :display_name => "Repeat flag"}
            bit1    :ack_not,   { :display_name => "0 = Acknowledge frame, 1 = standard frame"}
            bit2    :prio_class,{ :display_name => "Priority class (0=highest .. 3=lowest)"}
            bit2    :unused1,   { :display_name => "two unused bits (should be 00)"}
            end
        
        class L_DATA_Frame < BinData::Record
            endian :big
            # octet 0: TP1 control field
            bit2    :lpdu_code, { :display_name => "LPDU (2bit) 2=L_DATA.req 3=L_Poll_data.req"}
            bit1    :rep_flag,  { :display_name => "Repeat flag"}
            bit1    :ack_not,   { :display_name => "0 = Acknowledge frame, 1 = standard frame"}
            bit2    :prio_class,{ :display_name => "Priority class (0=highest .. 3=lowest)"}
            bit2    :unused1,   { :display_name => "two unused bits (should be 00)"}
            # octet 1+2: source
            uint16  :src_addr,  { :display_name => "Source Address"}
            # octet 3+4: destination
            uint16  :dst_addr,  { :display_name => "Destination Address"}
            # octet 5: control fields
            bit1    :daf,       { :display_name => "Dest.Address flag 0=physical 1=group"}
            bit3    :ctrlfield, { :display_name => "Network control field"}
            bit4    :datalength,{ :display_name => "Data length (bytes after octet #6)"}
            # octet 6 + octet 7: TPCI+APCI+6-bit data
            bit2    :tpci,      { :display_name => "TPCI control bits 8+7"}
            bit4    :seq,       { :display_name => "Packet sequence"}
            bit4    :apci,      { :display_name => "APCI control bits"}
            bit6    :apci_data, { :display_name => "APCI/Data combined"}
            # octet 8 .. end
            string  :data, {
                :read_length => lambda { datalength - 1 },
                :display_nane => "rest of frame"
            }
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
        
    end #module KNX
    
end #module

#~ data = [188, 17, 200, 18, 1, 242, 0, 128, 80, 171] .pack("c*")
#~ knxpacket = KNX_L_DATA_Frame.new(data)
#~ knxpacket.fields.each { |a|
    #~ puts "#{a.name} == #{a.inspect_in_object(knxpacket, :default)}"
#~ }
#puts knxpacket.inspect_detailed
#~ require 'knx_tools'
#puts addr2str(knxpacket.src_addr)