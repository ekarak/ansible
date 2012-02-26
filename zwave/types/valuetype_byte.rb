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

    module ZWave 
        
        # byte value type for OpenZWave (0-255)
        module ValueType_Byte

            # define type-specific OZW::Manager API calls
            def read_operation 
                return :GetValueAsByte 
            end
            
            def write_operation 
                return :SetValue_UInt8 
            end 
            
            # ZWave 1-byte values canonical form is a Fixnum between 0 and 255     
            def as_canonical_value()
                return( case current_value
                when 0..255 then current_value
                    else raise "#{self}: value #{current value} out of bounds 0..255"
                    end
                )
            end
            
            # ZWave 1-byte values protocol form is a Fixnum between 0 and 255
            def to_protocol_value(new_val)
                return( case new_val
                    when TrueClass then 255
                    when FalseClass then 0
                    when 0..255 then new_val
                    else raise "#{self}: value #{current value} out of bounds 0..255"
                    end
                )
            end 
            
            # return a human-readable representation of a ZWave frame
            def explain
                result = case @_commandClassId
                when 38 then 
                    case @current_value
                    when 0..99 then "#{@current_value} %"
                    else "Off"
                    end
                else "#{@current_value}"
                end    
                return(result)
            end
            
        end
        
    end
    
end
