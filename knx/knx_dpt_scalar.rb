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
        
        # KNX specification declares some special DPTs (5.001 and 5.003) that need
        # scalar adjustment functions to get the true value contained in a DPT frame.
        module ScalarValue
            
            # convert value to its scalar representation
            # e.g. in DPT5.001, 0x7F => 50(%), 0xFF => 100(%)
            def to_scalar(val, data_range, scalar_range)
                if data_range.is_a?(Range) and scalar_range.is_a?(Range) then   
                    a = (scalar_range.max - scalar_range.min).to_f / (data_range.max - data_range.min)
                    b = (scalar_range.min - data_range.min)
                    return (a*val + b).round
                else
                    return val
                end
            end
            
            # convert value from its scalar representation
            # e.g. in DPT5.001, 50(%) => 0x7F , 100(%) => 0xFF 
            def from_scalar(val, data_range, scalar_range)
                if data_range.is_a?(Range) and scalar_range.is_a?(Range) then
                    a = (scalar_range.max - scalar_range.min).to_f / (data_range.max - data_range.min)
                    b = (scalar_range.min - data_range.min)
                    #puts "a=#{a} b=#{b}"
                    return ((val - b) / a).round
                else
                    return val
                end
            end 
            
        end
        
    end
    
end
