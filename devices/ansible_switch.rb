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

require 'ansible_device'

module Ansible
    
    module AnsibleDevice
        
        class Switch < AbstractDevice
            
            def initialize(zwave_val, knx_cmd_val, knx_status_val=nil)
                puts "Declaring new Ansible Switch: #{self}"
                knx_cmd_val.declare_callback(:onUpdate) { |sender, cb, args| 
                    puts "KNX value #{knx_cmd_val.primary} updated! args=#{args}"
                    zwval = sender.current_value == 0 ? 0 : 1
                    zwave_val.set(zwval) # FIXME convert value domains
                }
                if knx_status_val then
                    zwave_val.declare_callback(:onUpdate) { | sender, cb, args|
                        puts "ZWave Switch #{zwval} HAS CHANGED!"
                        knxval = sender.current_value == 0 ? 0 : 1
                        knx_status_val.set(knxval)
                    }
                end
            end
            
            def bind
                
            end
            
        end
        
    end
    
end
