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
        # 1-bit canonical values
        #
        module Canonical_1bit
            
            # map 0,1 to canonical form (boolean)
            def to_canonical()
                return (self.data == 1)
            end
    
            # convert a canonical value (boolean) back to its protocol-specific form 
            def from_canonical(v)                
                self.data = ([true, 1].include?(v)) ? 1 : 0
            end
    
        end
        
    end
    
end
