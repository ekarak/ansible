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
        
    class Dimmer < Switch
        
        def bind_dimming(zwave_dimm_val, knx_dimm_val, knx_dimmstatus_val=nil)
            knx_dimm_val.add_callback(:onUpdate) { |sender, cb, args| 
                puts "KNX value #{sender} updated! args=#{args} canonical=#{sender.as_canonical_value}"
                zwval = sender.current_value.data * 99 / 255 
                zwave_dimm_val.set(zwval.round) # FIXME convert value domains
            }
            if knx_dimmstatus_val then
                zwave_dimm_val.add_callback(:onUpdate) { | sender, cb, args|
                    puts "ZWave value #{sender} HAS CHANGED #{args}"
                    knxval = sender.current_value.data * 255 / 99
                    knx_dimmstatus_val.set(knxval.round)
                }
            end
        end
        
    end #class
    
end
