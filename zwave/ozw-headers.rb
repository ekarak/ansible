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

require 'config'

# a generic Rexegp to parse C/C++ enums, must substitute %s in-place with enumeration name
ENUM_RE = %q(.* 
    enum \s* %s \s* 
    \{  
        ([^\{\}]*) 
    \}\;
)
# and the secondary regexp to parse enumeration items
# e.g.      			   Type_ValueChanged,	        /**< A node value has been updated from the Z-Wave network. */
ENUM_RE_LINE = /^ \s*  ([a-z_]+)  (\s*=\s*)* (\d*)  .*  \/\*\*\< \s (.*) \s \*\/$/ix
#                        md[1]      md[2]    md[3]                  md[4]  
#                       item name     =   default_index     textual_description
    
module OpenZWave

    # helper function to parse OpenZWave headers
    def OpenZWave.parse_ozw_headers(headerfile, enum_name)
        puts "Parsing enum #{enum_name}\tfrom #{headerfile} ..." if $DEBUG
        #~ puts enum_re % enum_name
        foo = File.open(headerfile).read
        enum_array = {}
        if enum = Regexp.new(ENUM_RE % enum_name,  Regexp::EXTENDED | Regexp::IGNORECASE | Regexp::MULTILINE).match(foo) then
            index = 0
            #~ puts enum[1].inspect
            #~ puts '-----------------'
            enum[1].split("\n").each { |line|
                if md = ENUM_RE_LINE.match(line) then
                    #puts md[1..-1].inspect
                    index =  (md[2] and md[3].length > 0) ? md[3].to_i : index+1
                    key, value = md[1], md[4]
                    enum_array[index] = [key, value]
                    # define back-reference to index as a module constant
                    cname = enum_name+'_'+key.split('_')[1]
                    #puts "defining constant OpenZWave::#{cname} == #{index}"
                    const_set(key, index)
                    puts "#{enum_name}[#{index}] = [#{key}, #{value}]" if $DEBUG
                end
            }
            return enum_array
        end
    end
    
    # define OpenZWave global lookup tables
    NotificationTypes = parse_ozw_headers( File.join(OZW_SRC, "Notification.h"), "NotificationType" )
    ControllerCommands = parse_ozw_headers( File.join(OZW_SRC, "Driver.h"), "ControllerCommand" )
    ControllerStates = parse_ozw_headers( File.join(OZW_SRC, "Driver.h"), "ControllerState" )
    ValueGenres = parse_ozw_headers( File.join(OZW_SRC, "value_classes", "ValueID.h"), "ValueGenre" )
    ValueTypes = parse_ozw_headers( File.join(OZW_SRC, "value_classes", "ValueID.h"), "ValueType" )
    
end
    

#CommandClassesByID defined in zwave_command_classes.rb

