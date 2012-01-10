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

# 2-byte unsigned value

module Ansible
    
    module KNX
        
        class KNX_DPT7 < BitStruct
            unsigned :value, 16, "Value"
        end
        
         class KNXValue_DPT7 < KNXValue
             # check value range
             def KNXValue_DPT7.range_check(value)
                 return value.between?(0, 2**16-1)
             end
             
             def to_apdu(apci_code = 0x40);
                 return [0, apci_code] << [@current_value].pack("N") #CHECKME 
            end
            
            # update internal state from raw KNX frame
            def update_from_frame(frame)
                @frame = KNX_DPT7.new(frame.data)
                puts "--- DPT7 frame: #{@frame.inspect_detailed}"
                update(@frame.value)
            end
         end
         
    end
    
end
        
        
=begin
puts KNX_DPT2.bit_length
puts KNX_DPT2.new([0x00].pack('c')).inspect #
puts KNX_DPT2.new([0x01].pack('c')).inspect #
puts KNX_DPT2.new([0x02].pack('c')).inspect #
puts KNX_DPT2.new([0x03].pack('c')).inspect #

puts [0x02].pack('c').inspect

=begin
7.001 pulses
7.002 time(ms)
7.003 time(10ms)
7.004 time(100ms)
7.005 time(s)
7.006 time(min)
7.007 time(h)
7.012 current(mA)
=end