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
        # 1-bit canonical values for KNX
        # implements value casting to/from the canonical type, a boolean value 
        module Canonical_1bit
            
            # DPT1 canonical values
            # ---------------------
            # Use Ruby convention for booleans in order to convert 
            # input value of (nil, false) into 0, otherwise 1
            
            # data is 1 ==> true, false otherwise
            def as_canonical_value()
                return (current_value.data.eql?1)
            end
    
            # v is true? 1 : 0 
            def to_protocol_value(v)
                return (v ? 1 : 0)
            end
    
        end
        
    end
    
end
