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
    
    # root class describing an Ansible Device, i.e. a device controlled 
    # at least by one automation protocol supported by Ansible
    #
    # ===Arguments: 
    # [hashmap]  
    #   hash consisting of Symbol => AnsibleValue pairs e.g. 
    #   {
    #    :onoff => KNXValue.new("1.001", "1/0/20")
    #   } 
    #
    # ===Example:
    #   obj.fire_callback(:onChange, 'GROUPADDR', :arg1, :arg2, :arg3)
    #
    class Device
    
        # initialize an Ansible Device
        def initialize(hashmap)
            # sanity check: check argument validity
            args_valid = true
            if hashmap.is_a?Hash then
                hashmap.each { |k,v|
                    args_valid = args_valid and (k.is_a?Symbol) and (v.is_a?AnsibleValue)
                }
            else
                args_valid = false
            end
            raise "#{self.class}.new requires a hash map of Symbol => AnsibleValue!!!" unless args_valid
            #
            # store hashmap
            @hashmap = hashmap
            # link values
            link()
        end
        
    end
        
    
    #
    # load all known Ansible Device classes
    Dir["devices/*.rb"].each { |f| load f }

end
