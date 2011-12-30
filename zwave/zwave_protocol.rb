#~ Project Ansible
#~ (c) 2011 Elias Karakoulakis <elias.karakoulakis@gmail.com>

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