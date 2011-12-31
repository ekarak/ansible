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

require 'rubygems'
require 'bit-struct'

#~ // ID Packing:
#~ // Bits
#~ // 24-31:	8 bits. Node ID of device
#~ // 22-23:	2 bits. genre of value (see ValueGenre enum).
#~ // 14-21:	8 bits. ID of command class that created and manages this value.
#~ // 12-13:	2 bits. Unused.
#~ // 04-11:	8 bits. Index of value within all the value created by the command class
#~ //                  instance (in configuration parameters, this is also the parameter ID).
#~ // 00-03:	4 bits. Type of value (bool, byte, string etc).
class OZW_EventID_id < BitStruct
    unsigned    :node_id,       8, "Node ID of device"
    unsigned    :value_genre,   2, "Value Genre"
    unsigned    :cmd_class,     8, "command class"
    unsigned    :unused1,       2, "(unused)"
    unsigned    :value_idx,     8, "value index"
    unsigned    :value_type,    4, "value type( bool, byte, string etc)"
end

#~ // ID1 Packing:
#~ // Bits
#~ // 24-31	8 bits. Instance Index of the command class.
class OZW_EventID_id1 < BitStruct
    unsigned    :cmd_class_instance, 8, "cmd class instance"
    unsigned    :unused2   , 24, "(unused)"    
end