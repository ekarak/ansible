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

#
# DPT2: 2-bit control value
#

module Ansible
    
    module KNX

        module DPT2
            
            # DPT2 frame description. 
            # Always 8-bit aligned.
            class DPT2Struct < DPTStruct
                bit2    :apci_pad, {
                    :display_name => "APCI info (not useful)"
                }
                bit4    :pad1 
                bit1    :priority, {
                    :display_name => "0=No Control 1=Priority"
                }
                bit1    :data, :display_name => "Value"
            end
            
            # DPT basetype info hash
            Basetype = {
                :bitlength => 2,
                :valuetype => :composite,
                :desc => "1-bit value with priority"
            }
            
            # DPT subtypes info hash
            Subtypes = {
                # 2.001 switch control
                "001" => { :use => "G",
                    :name => "DPT_Switch_Control", 
                    :desc => "switch with priority", 
                    :enc => { 0 => "Off", 1 => "On" }
                },
                # 2.002 boolean control
                "002" => { :use => "G",
                    :name => "DPT_Bool_Control", 
                    :desc => "boolean with priority", 
                    :enc => { 0 => "false", 1 => "true" }
                },
                # 2.003 enable control
                "003" => {  :use => "FB",
                    :name => "DPT_Emable_Control", 
                    :desc => "enable with priority", 
                    :enc => { 0 => "Disabled", 1 => "Enabled" }
                },

                # 2.004 ramp control
                "004" => { :use => "FB",
                    :name => "DPT_Ramp_Control", 
                    :desc => "ramp with priority", 
                    :enc => { 0 => "No ramp", 1 => "Ramp" }
                },

                # 2.005 alarm control
                "005" => { :use => "FB",
                    :name => "DPT_Alarm_Control", 
                    :desc => "alarm with priority", 
                    :enc => { 0 => "No alarm", 1 => "Alarm" }
                },

                # 2.006 binary value control
                "006" => { :use => "FB",
                    :name => "DPT_BinaryValue_Control", 
                    :desc => "binary value with priority", 
                    :enc => { 0 => "Off", 1 => "On" }
                },

                # 2.007 step control
                "007" => { :use => "FB",
                    :name => "DPT_Step_Control", 
                    :desc => "step with priority", 
                    :enc => { 0 => "Off", 1 => "On" }
                },

                # 2.008 Direction1 control
                "008" => { :use => "FB",
                    :name => "DPT_Direction1_Control", 
                    :desc => "direction 1 with priority", 
                    :enc => { 0 => "Off", 1 => "On" }
                },
               
                # 2.009 Direction2 control
                "009" => { :use => "FB",
                    :name => "DPT_Direction2_Control", 
                    :desc => "direction 2 with priority", 
                    :enc => { 0 => "Off", 1 => "On" }
                },
                
                # 2.010 start control
                "001" => { :use => "FB",
                    :name => "DPT_Start_Control", 
                    :desc => "start with priority", 
                    :enc => { 0..1 => "No control", 2 => "Off", 3 => "On" }
                },

                # 2.011 state control
                "001" => { :use => "FB",
                    :name => "DPT_Switch_Control", :desc => "switch", 
                    :enc => { 0..1 => "No control", 2 => "Off", 3 => "On" }
                },

                # 2.012 invert control
                "001" => { :use => "FB",
                    :name => "DPT_Switch_Control", :desc => "switch", 
                    :enc => { 0..1 => "No control", 2 => "Off", 3 => "On" }
                }
            }
            
            include Canonical_1bit
             
        end #class
        
    end
    
end

=begin
puts KNX_DPT2.bit_length
puts KNX_DPT2.new([0x00].pack('c')).inspect #
puts KNX_DPT2.new([0x01].pack('c')).inspect #
puts KNX_DPT2.new([0x02].pack('c')).inspect #
puts KNX_DPT2.new([0x03].pack('c')).inspect #

puts [0x02].pack('c').inspect
=begin
=end