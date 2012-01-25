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
        # DPT15.*: Access data
        #        
        module DPT15
        
            # Bitstruct to parse a DPT4 frame. 
            # Always 8-bit aligned.
            class FrameStruct < BinData::Record
                bit4 :d6, :display_name => "D6"
                bit4 :d5, :display_name => "D5"
                #
                bit4 :d4, :display_name => "D4"
                bit4 :d3, :display_name => "D3"
                #
                bit4 :d2, :display_name => "D2"
                bit4 :d1, :display_name => "D1"
                #
                bit1  :e
                bit1  :p
                bit1  :d
                bit1  :c
                bit4  :idx
            end
            
            # DPT15 base type info
            Basetype = {
                :bitlength => 32,
                :valuetype => :basic,
                :desc => "4-byte access control data"
            }
            
            # DPT8 subtypes info
            Subtypes = {
                "000" => {
                    :name => "DPT_Access_Data"
                }
            }
            
        end
        
    end
    
end

