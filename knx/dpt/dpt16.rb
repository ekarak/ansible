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
        # DPT16: ASCII string
        #
        module DPT16
        
            # Bitstruct to parse a DPT16 frame. 
            # Always 8-bit aligned.
            class FrameStruct < BinData::Record
                string :data, :length => 14
            end
            
            # DPT16 basetype info
            Basetype = {
                :bitlength => 14*8,
                :valuetype => :basic,
                :desc => "14-character string"
            }
            
            # DPT9 subtypes
            Subtypes = {    
                # 16.000 ASCII string
                "000" => { :use => "G",
                    :name => "DPT_String_ASCII", :desc => "ASCII string",
                    :force_encoding => "US-ASCII"
                },

                # 16.001 ISO-8859-1 string
                "001" => { :use => "G",
                    :name => "DPT_String_8859_1", :desc => "ISO-8859-1 string",
                    :force_encoding => "ISO-8859-1"
                },
            }
            
        end
        
    end

end

