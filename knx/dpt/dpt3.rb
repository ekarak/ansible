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
        # DPT3.*: 4-bit dimming/blinds control 
        #       
        module DPT3
            
            # Bitstruct to parse a DPT3 frame. 
            # Always 8-bit aligned.
            class DPT3_Frame < DPTFrame
                bit2    :apci_pad, :display_name => "APCI data"
                bit2    :pad1
                bit1    :decr_incr, :display_name => "Decrease(0) / Increase(1)"
                bit3    :data,  {
                    :display_name => "0=break, 1-7 = amount of intervals between 1..100%",
                    :enc => {
                        0 => "break",
                        1 => "ival=50%",
                        2 => "ival=25%",
                        3 => "ival=12,5%",
                        4 => "ival=6,25%",
                        5 => "ival=3,125%",
                        6 => "ival=1,5625%",
                        7 => "ival=0.78125%"
                    }
                }
            end
                       
            Basetype = {
                :bitlength => 4,
                :valuetype => :composite,
                :desc => "4-bit relative dimming control"
            }
            
            Subtypes = {
                # 3.007 dimming control
                "3.007" => {
                    :name => "DPT_Control_Dimming",
                    :desc => "dimming control"
                },
                
                # 3.008 blind control
                "3.008" => {
                    :name => "DPT_Control_Blinds",
                    :desc => "blinds control"
                }
            }
            
        end

    end

end

=begin
        2.6.3.5 Behavior
Status
off     dimming actuator switched off
on      dimming actuator switched on, constant brightness, at least
        minimal brightness dimming
dimming actuator switched on, moving from actual value in direction of
        set value
Events
    position = 0        off command
    position = 1        on command
    control = up dX     command, dX more bright dimming
    control = down dX   command, dX less bright dimming
    control = stop      stop command
    value = 0           dimming value = off
    value = x%          dimming value = x% (not zero)
    value_reached       actual value reached set value

The step size dX for up and down dimming may be 1/1, 1/2, 1/4, 1/8, 1/16, 1/32 and 1/64 of
the full dimming range (0 - FFh).

3.007 dimming control
3.008 blind control
=end
