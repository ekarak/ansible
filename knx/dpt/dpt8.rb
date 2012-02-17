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
        # DPT8.*: 2-byte signed value
        #
        module DPT8 
        
            # Bitstruct to parse a DPT8 frame. 
            # Always 8-bit aligned.
            class DPT8_Frame < DPTFrame
                int16  :data, :display_name => "Value"
            end

            # DPT8 basetype info
            Basetype = {
                :bitlength => 16,
                :valuetype => :basic,
                :desc => "16-bit signed value"
            }
            
            # DPT8 subtypes info
            Subtypes = {
                # 8.001 pulses difference
                "001" => {
                    :name => "DPT_Value_2_Count", 
                    :desc => "pulses", 
                    :unit => "pulses"
                },
                
                # 8.002 time lag (ms)
                "002" => {
                    :name => "DPT_DeltaTimeMsec", 
                    :desc => "time lag(ms)",
                    :unit => "milliseconds"
                },
                
                # 8.003 time lag (10ms)
                "003" => {
                    :name => "DPT_DeltaTime10Msec", 
                    :desc => "time lag(10ms)",
                    :unit => "centiseconds"
                },
                
                # 8.004 time lag (100ms)
                "004" => {
                    :name => "DPT_DeltaTime100Msec", 
                    :desc => "time lag(100ms)",
                    :unit => "deciseconds"
                },
                
                # 8.005 time lag (sec)
                "005" => {
                    :name => "DPT_DeltaTimeSec", 
                    :desc => "time lag(s)",
                    :unit => "seconds"
                },
                
                # 8.006 time lag (min)
                "006" => {
                    :name => "DPT_DeltaTimeMin", 
                    :desc => "time lag(min)",
                    :unit => "minutes"
                },
                
                # 8.007 time lag (hour)
                "007" => {
                    :name => "DPT_DeltaTimeHrs", 
                    :desc => "time lag(hrs)",
                    :unit => "hours"
                },
                
                # 8.010 percentage difference (%)
                "010" => {
                    :name => "DPT_Percent_V16", 
                    :desc => "percentage difference", 
                    :unit => "%"
                },

                # 8.011 rotation angle (deg)
                "011" => {
                    :name => "DPT_RotationAngle", 
                    :desc => "angle(degrees)",
                    :unit => "°"
                },
            }
            
        end
         
    end
    
end