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
        # DPT11.*: date
        #        
        module DPT11

            class DPT11_Frame < DPTFrame
                bit3 :pad1 
                bit5 :dayofmonth,  {
                    :display_name =>  "Day of month (1..31)", :range => 1..31
                }
                #
                bit4 :pad2
                bit4 :month, {
                    :display_name => "Month (1..12)", :range => 1..12 
                }
                #
                bit1 :pad3
                bit7 :year,  {
                    :display_name => "Year 0..99 (<90 => 20xx, >=90 => 19xx)", :range => 0..99 
                } 
            end
            
            # DPT11 base type info
            Basetype = {
                :bitlength => 24,
                :valuetype => :composite,
                :desc => "3-byte date value"
            }
            
            
            # DPT11 subtypes info
            Subtypes = {   
                # 11.001 date
                "001" => {
                    :name => "DPT_Date", :desc => "Date"
                }
            }
            
        end
        
    end
    
end

