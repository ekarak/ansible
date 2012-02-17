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

require 'bindata'

module Ansible
    
    module KNX
        
        # a base class for DPT data structures.
        # derives from BinData::Record,
        # implements some common stuff 
        class DPTFrame < BinData::Record
            # endianness in KNX is big
            endian :big
        
            # make sure all frame fields are valid (within min,max range) 
            def validate_ranges()
                # range checking is global: applies to all subtypes
                field_names.each { |fieldname|
                    # skip padding fields
                    next if /pad/.match(fieldname)
                    field = self.send(fieldname)
                    if range = field.get_parameter(:range) then
                        raise "#{self}: field #{fieldname} value (#{field.value}) out of range #{range}" unless range === field.value
                    end
                }
            end    
        end

        #
        # load all known DPT modules
        Dir["knx/dpt/*.rb"].each { |f| load f }

    end
    
end
