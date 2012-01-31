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
        # DPT4: 8-bit character
        #
        module DPT4
            
            # Bitstruct to parse a DPT4 frame. 
            # Always 8-bit aligned.
            class DPT4Struct < DPTStruct
                uint8 :data, :display_name => "Character"
            end

            Basetype =  {
                :bitlength => 8,
                :valuetype => :basic,
                :desc => "8-bit character"
            }
                        
            Subtypes = {
                # 4.001 character (ASCII)
                "001" => {
                    :name => "DPT_Char_ASCII",
                    :desc => "ASCII character (0-127)",
                    :range => 0..127,
                    :use => "G",
                },
                # 4.002 character (ISO-8859-1)
                "002" => {
                    :name => "DPT_Char_8859_1",
                    :desc => "ISO-8859-1 character (0..255)",
                    :use => "G",
                }
            }
            
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
=end
