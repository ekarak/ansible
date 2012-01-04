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

require 'bit-struct'

# 2-byte signed value

module Ansible
    
    module KNX
        
        class KNX_DPT8 < BitStruct
            unsigned :value,    16, "Value"
        end

    end
    
end
        
=begin
8.001 pulses difference
8.002 time lag (ms)
8.003 time lag (10ms)
8.004 time lag (100ms)
8.005 time lag (sec)
8.006 time lag (min)
8.007 time lag (hour)
8.010 percentage difference (%)
8.011 rotation angle (deg)
=end