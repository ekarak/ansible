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

    # a Dimmer is a Switch with additional capabilites (duh)
    class Dimmer < Switch
        
        def link
            dimming = @hashmap[:dimming]
            status = @hashmap[:dimming_status]
            master = @hashmap[:master_control]
            unless dimming.is_a?AnsibleValue
                raise "#{self}.link: must supply AnsibleValues for :dimming!"
            end
            # map dimming value updates to master_control 
            dimming.add_callback(:onUpdate, self) { |sender, cb, args| 
                puts "   (#{sender.class}) #{sender} input value updated! args=#{args}"
                # convert value domains 
                cv = sender.as_canonical_value
                newval = master.to_protocol_value(cv)
                puts "   #{self} setting output #{output} +++ cv=#{cv} newval=#{newval}"
                target.set(newval)
                # also update status value, if defined
                status.set(newval) unless status.nil?                    
            }
            # also update dimming status value, if defined
            master.add_callback(:onUpdate, self) { |sender, cb, args|
                # convert value domains 
                cv = sender.as_canonical_value
                newval = master.to_protocol_value(cv)
                #
                status = @hashmap[:switch_status]
                puts "   updating dimming status value (#{status}) new val=#{newval}!"
                status.set(newval)
            } if status.is_a?AnsibleValue
            # call upstream linking method in Switch, if any
            super()
=begin
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
=end
        end
        
    end #class
    
end
