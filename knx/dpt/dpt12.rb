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

module Ansible
    
    module KNX
        
        #
        # DPT12.*:  4-byte unsigned value
        #        
        module DPT12

            class DPT12Struct < DPTStruct
                uint32 :data, { 
                    :display_name => "32-bit value",
                    :range => 0..2**32-1
                }
            end

            # DPT12 base type info
            Basetype = {
                :bitlength => 32,
                :valuetype => :basic,
                :desc => "4-byte unsigned value"
            }
                        
            # DPT12 subtype info
            Subtypes = {   
                # 12.001 counter pulses
                "001" => {
                    :name => "DPT_Value_4_Ucount", :desc => "counter pulses"
                }
            }
            
        end
        
    end
    
end

