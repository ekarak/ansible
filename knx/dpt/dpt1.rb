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

require 'bit-struct'

module Ansible
    
    module KNX

        # 8-bit unsigned value
        class KNX_DPT1 < BitStruct
            unsigned  :apci,   2, "APCI info (not useful)"
            unsigned  :data, 6, "6 bit of useful data"
        end

        class KNXValue_DPT1 < KNXValue
            def to_apdu();  
                return [0, 0x80 | @current_value] 
            end
            def update_from_frame(frame)
                @frame = KNX_DPT1.new(frame.data)
                puts "--- DPT1 frame: #{@frame.inspect_detailed}"
                update(@frame.data)
            end
        end #class
        
    end
    
end
