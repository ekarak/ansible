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
        # DPT13: 4-byte signed value
        #
        module DPT13
            
            class FrameStruct < BinData::Record
                endian :big
                #
                int32 :data,  { 
                    :display_name => "32-bit signed value",
                    :range => -2**31..2**31-1
                }
            end

            # DPT13 base type info
            Basetype = {
                :bitlength => 32,
                :valuetype => :basic,
                :desc => "4-byte signed value"
            }
            
            # DPT13 subtypes
            Subtypes = {
                # 13.001 counter pulses (signed)
                "001" => {
                    :name => "DPT_Value_4_Count", :desc => "counter pulses (signed)", 
                    :unit => "pulses"
                },
                
                # 13.010 active energy (Wh)
                "010" => {
                    :name => "DPT_ActiveEnergy", :desc => "active energy (Wh)", 
                    :unit => "Wh"
                },
                
                # 13.011 apparent energy (VAh)
                "011" => {
                    :name => "DPT_ApparantEnergy", :desc => "apparent energy (VAh)", 
                    :unit => "VAh"
                },
                
                # 13.012 reactive energy (VARh)
                "012" => {
                    :name => "DPT_ReactiveEnergy", :desc => "reactive energy (VARh)", 
                    :unit => "VARh"
                },
                
                # 13.013 active energy (KWh)
                "013" => {
                    :name => "DPT_ActiveEnergy_kWh", :desc => "active energy (kWh)", 
                    :unit => "kWh"
                },
                
                # 13.014 apparent energy (kVAh)
                "014" => {
                    :name => "DPT_ApparantEnergy_kVAh", :desc => "apparent energy (kVAh)", 
                    :unit => "VAh"
                },
                
                # 13.015 reactive energy (kVARh)
                "015" => {
                    :name => "DPT_ReactiveEnergy_kVARh", :desc => "reactive energy (kVARh)", 
                    :unit => "kVARh"
                },
                
                # 13.100 time lag(s)
                "100" => {
                    :name => "DPT_LongDeltaTimeSec", :desc => "time lag(s)", 
                    :unit => "s"
                },
            }
        end
    end
end
