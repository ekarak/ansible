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
        
        module ValueType_Byte

            # define type-specific OZW::Manager API calls
            def read_operation 
                return :GetValueAsByte 
            end
            
            def write_operation 
                return :SetValue_UInt8 
            end 
            #            
            def as_canonical_value()
                puts 'TODO:: zwave_byte: as_canonical'
                return (current_value > 0)
            end
            
            #
            def to_protocol_value(new_val)
                puts 'TODO:: zwave_byte: to_protocol'
                result = nil
                if [TrueClass, FalseClass].include?(new_val.class)
                    result = new_val ? 1 : 0
                end
            end 
            
            # return a human-readable representation of a ZWave frame
            def explain
            end
        end
        
    end
    
end
