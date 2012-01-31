# encoding: ISO-8859-1

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
        # DPT5: 8-bit unsigned value
        #
        module DPT5
            
            # Bitstruct to parse a DPT5 frame. 
            # Always 8-bit aligned.
            class DPT5Struct < DPTStruct
                uint8  :data,  {
                    :display_name => "8-bit unsigned value",
                    :range => 0..255
                }
            end
            
            # DPT base type
            Basetype = {
                :bitlength => 8,
                :valuetype => :basic,
                :desc => "8-bit unsigned value"
            }
            # DPT subtypes
            Subtypes = {
                # 5.001 percentage (0=0..ff=100%)
                "001" => {
                    :name => "DPT_Scaling", :desc => "percent", 
                    :unit => "%", :scalar_range => 0..100
                },
                
                # 5.003 angle (degrees 0=0, ff=360)
                "003" => {
                    :name => "DPT_Angle", :desc => "angle degrees", 
                    :unit => "°", :scalar_range => 0..360
                },
                
                # 5.004 percentage (0..255%)
                "004" => {
                    :name => "DPT_Percent_U8", :desc => "percent", 
                    :unit => "%", 
                },
                
                # 5.005 ratio (0..255)
                "005" => {
                    :name => "DPT_DecimalFactor", :desc => "ratio", 
                    :unit => "ratio", 
                },
                
                # 5.006 tariff (0..255)
                "006" => {
                    :name => "DPT_Tariff", :desc => "tariff", 
                    :unit => "tariff", 
                },
                
                # 5.010 counter pulses (0..255)
                "010" => {
                    :name => "DPT_Value_1_Ucount", :desc => "counter pulses", 
                    :unit => "pulses",
                },
            }

        end 
        
    end
    
end

