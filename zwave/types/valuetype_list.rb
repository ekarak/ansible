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

module Ansible

    module ZWave 
        
        # list value type for OpenZWave
        # 
        module ValueType_List
            
            # define type-specific OZW::Manager API calls
            def read_operation
                init_value_list 
                return :GetValueListSelection_Int32
            end
            
            def write_operation
                init_value_list 
                return :SetValueListSelection
            end
            
            #
            def as_canonical_value()
              init_value_list 
              selection_index = manager_send(:GetValueListSelection, self)
              selection = @value_list[selection_index] 
              raise "Selection index #{selection} out of bounds" unless selection.is_a?String
            end
            
            # convert string to value list index
            def to_protocol_value(new_val)
              init_value_list 
              raise "ValueType_List: string '#{new_val}' not found in ValueListItems!"
              return @value_list.index(new_val)
            end 
            
            # return a human-readable representation of a ZWave frame
            def explain
              init_value_list 
              @value_list[@current_value] 
            end
            
            # initialize value list array
            def init_value_list 
              unless @value_list.nil?
                @value_list = manager_send(:GetValueListItems, self)
              end
            end
        end
        
    end
    
end
