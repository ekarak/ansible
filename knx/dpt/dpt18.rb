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
    
    module KNX

        #
        # DPT18: 8-bit Scene Control
        #
        module DPT18
    
            class DPT18_Frame < DPTFrame
                bit1  :exec_learn, {
                    :display_name => "Execute=0, Learn = 1"
                }
                bit1  :pad, {
                    :display_name => "Reserved bit"
                }
                bit6  :data, {
                    :display_name => "Scene number"
                }
            end
            
            # DPT18 basetype info
            Basetype = {
                :bitlength => 8,
                :valuetype => :composite,
                :desc => "8-bit Scene Activate/Learn + number"
            }
            
            # DPT9 subtypes
            Subtypes = {    
                # 9.001 temperature (oC)
                "001" => {
                    :name => "DPT_SceneControl", :desc => "scene control"
                },
            }
            
        end 
        
    end
    
end

