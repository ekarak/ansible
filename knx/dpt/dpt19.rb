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
        # DPT19: 8-byte Date and Time
        #
        module DPT19
    
            class DPT19Struct < DPTStruct
                # byte 8 (MSB)
                uint8 :year, { 
                    :display_name => "Year" 
                }
                # byte 7
                bit4    :pad7
                bit4    :month, {
                    :display_name => "Month"
                }
                # byte 6
                bit3    :pad6
                bit5    :dayofmonth, {
                    :display_name => "Day of month"
                }
                # byte 5
                bit3    :dayofweek, {
                    :display_name => "Day of week"
                }
                bit5    :hourofday, {
                :display_name => "Hour of day"
                }
                # byte 4
                bit2    :pad4
                bit6    :minutes, {
                    :display_name => "Minutes"
                }
                # byte 3
                bit2    :pad3
                bit6    :seconds, {
                    :display_name => "Seconds"
                }
                # byte 2
                bit1    :flag_F   #
                bit1    :flag_WD  #
                bit1    :flag_NWD # no week day
                bit1    :flag_NY  # no year
                bit1    :flag_ND  # no day
                bit1    :flag_NDOW # no day of week
                bit1    :flag_NT   # no time
                bit1    :flag_SUTI # summertime
                # byte 1
                bit1    :flag_CLQ #clock accuracy
                bit7    :pad1
            end
            
            # DPT18 basetype info
            Basetype = {
                :bitlength => 8,
                :valuetype => :composite,
                :desc => "8-bit Scene Activate/Learn + number"
            }
            
            # DPT9 subtypes
            Subtypes = {    
                # 9.001 temperature (oC)
                "001" => {
                    :name => "DPT_SceneControl", :desc => "scene control"
                },
            }
            
        end 
        
    end
    
end

