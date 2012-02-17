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

        #
        # DPT17: Scene number
        #
        module DPT17
        
            # Bitstruct to parse a DPT17 frame. 
            # Always 8-bit aligned.
            class DPT17_Frame < DPTFrame
                bit2 :pad
                bit6 :data, { 
                    :display_name => "Scene number"
                }
            end
            
            # DPT16 basetype info
            Basetype = {
                :bitlength => 8,
                :valuetype => :basic,
                :desc => "scene number"
            }
            
            # DPT9 subtypes
            Subtypes = {    
                # 17.001 Scene number
                "001" => { :use => "G",
                    :name => "DPT_SceneNumber", :desc => "Scene Number",
                },
            }
            
        end
        
    end

end

