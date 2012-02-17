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

    # a Switch is a device controlled by a boolean state: False/Off/0 and True/On/1
    
    class Switch < AbstractDevice
        
        # initialize an Ansible::Switch.
        # ctrl_value (control value) is the value controlling the end device
        def initialize(ctrl_value)
            super()
            puts "Declaring new Ansible Switch: #{self}"
            input(ctrl_value)
            output(ctrl_value)
        end
        
    end
    
end
