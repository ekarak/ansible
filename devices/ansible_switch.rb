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

    #
    # a Switch is a device controlled by a boolean state: False/Off/0 and True/On/1
    class Switch < Device
        
        def link
            switch = @hashmap[:switch]
            status = @hashmap[:switch_status]
            master = @hashmap[:master_control]
            unless [switch, master].select{ |v| not v.is_a? AnsibleValue }.empty?
                raise "#{self}.link: must supply AnsibleValues for :master_control and :switch!"
            end
            # map switch value updates to master_control 
            switch.add_callback(:onUpdate, self) { |sender, cb, args| 
                puts "   (#{sender.class}) #{sender} input value updated! args=#{args}"
                # convert value domains 
                cv = sender.as_canonical_value
                newval = master.to_protocol_value(cv)
                puts "   #{self} setting master #{master} +++ cv=#{cv} newval=#{newval}"
                master.set(newval)
            }
            # also update status value, if defined
            if status.is_a?AnsibleValue then
                puts "...also adding status feedback command #{status}"
                master.add_callback(:onUpdate, self) { |sender, cb, args|
                    # convert value domains 
                    cv = sender.as_canonical_value
                    newval = master.to_protocol_value(cv)
                    #
                    status = @hashmap[:switch_status]
                    puts "   updating on/off status value (#{status}) new val=#{newval}!"
                    status.set(newval)
                }
            end
        end #def
        
    end
    
end
