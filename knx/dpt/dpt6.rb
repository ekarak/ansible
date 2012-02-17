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
# DPT6.*: 8-bit signed value
#

module Ansible
    
    module KNX
        
        module DPT6
            
            # Bitstruct to parse a DPT6 frame. 
            # Always 8-bit aligned.      
            class DPT6_Frame < DPTFrame
                int8 :data, :display_name => "Signed value -128..127"
            end

            # DPT Basetype info
            Basetype = {
                :bitlength => 8,
                :valuetype => :basic,
                :desc => "8-bit signed value",
                :range => -128..127
            }            
            # DPT subtypes info
            Subtypes = {
                # 6.001 percentage (-128%..127%)
                "001" => {
                    :name => "DPT_Switch", :desc => "percent",
                    :unit => "%",  
                },
                
                # 6.002 counter pulses (-128..127)
                "002" => {
                    :name => "DPT_Bool", :desc => "counter pulses",
                    :unit => "pulses"
                },
                # 
            }
            
        end
        
    end
    
end
=begin
puts KNX_DPT6.bit_length
puts KNX_DPT6.new([0x32].pack('c')).inspect # 50
puts KNX_DPT6.new([0xce].pack('c')).inspect # -50
=end