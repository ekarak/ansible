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
        # DPT10.*: time
        #
        module DPT10
            
            # DPTStruct to parse a DPT10 frame. 
            # Always 8-bit aligned.
            class DPT10Struct < DPTStruct
                bit3 :dayofweek, {
                    :display_name => "Day of week", 
                    :range => 0..7, :data_desc => {
                        0 => "(no day set)",
                        1 => "Monday",
                        2 => "Tuesday",
                        3 => "Wednesday",
                        4 => "Thursday",
                        5 => "Friday",
                        6 => "Saturday",
                        7 => "Sunday"
                    }    
                }
                bit5 :hour, {
                    :display_name =>  "Hour", :range => 0..23
                }
                #
                bit2 :pad2
                bit6 :minutes, {
                    :display_name =>  "Minutes", :range => 0..59
                }
                #
                bit2 :pad3
                bit6 :seconds, {
                    :display_name =>  "Seconds", :range => 0..59
                }
            end

            # DPT10 base type info
            Basetype = {
                :bitlength => 24,
                :valuetype => :composite,
                :desc => "day of week + time of day"
            }
            
            # DPT10 subtypes info
            Subtypes = {
                # 10.001 time of day
                "001" => {
                    :name => "DPT_TimeOfDay", :desc => "time of day"
                }
            }

        end
        
    end
    
end
