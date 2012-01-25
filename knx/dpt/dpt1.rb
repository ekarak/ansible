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
        # DPT1: 1-bit (boolean) value
        #
        module DPT1
            
            # Bitstruct to parse a DPT1 frame. 
            # Always 8-bit aligned.
            class FrameStruct < BinData::Record
                endian :big
                #
                bit2  :apci, :display_name => "APCI info (not useful)"
                bit6  :data, :display_name => "6 bit of useful data", :range => 0..1
            end
            
            # DPT basetype info hash
            Basetype = {
                :bitlength => 1,
                :valuetype => :basic,
                :desc => "1-bit value"
            }
            
            # DPT subtypes info hash
            Subtypes = {
                # 1.001 on/off
                "001" => { :use => "G",
                    :name => "DPT_Switch", 
                    :desc => "switch", 
                    :data_desc => { 0 => "Off", 1 => "On" }
                },
                
                # 1.002 boolean
                "002" => { :use => "G",
                    :name => "DPT_Bool", 
                    :desc => "bool", 
                    :data_desc => { 0 => "false", 1 => "true" }
                },
                
                # 1.003 enable
                "003" => { :use => "G",
                    :name => "DPT_Enable", 
                    :desc => "enable", 
                    :data_desc => { 0 => "disable", 1 => "enable" }
                },
                
                # 1.004 ramp
                "004" => { :use => "FB",
                    :name => "DPT_Ramp", 
                    :desc => "ramp", 
                    :data_desc => { 0 => "No ramp", 1 => "Ramp" }
                },
                
                # 1.005 alarm
                "005" => { :use => "FB",
                    :name => "DPT_Alarm", 
                    :desc => "alarm", 
                    :data_desc => { 0 => "No alarm", 1 => "Alarm" }
                },
                
                # 1.006 binary value
                "006" => { :use => "FB",
                    :name => "DPT_BinaryValue", 
                    :desc => "binary value", 
                    :data_desc => { 0 => "Low", 1 => "High" }
                },
                
                # 1.007 step
                "007" => { :use => "FB",
                    :name => "DPT_Step", 
                    :desc => "step", 
                    :data_desc => { 0 => "Decrease", 1 => "Increase" }
                },
                
                # 1.008 up/down
                "008" => { :use => "G",
                    :name => "DPT_UpDown", 
                    :desc => "up/down", 
                    :data_desc => { 0 => "Up", 1 => "Down" }
                },
                
                # 1.009 open/close
                "009" => { :use => "G",
                    :name => "DPT_OpenClose", 
                    :desc => "open/close", 
                    :data_desc => { 0 => "Open", 1 => "Close" }
                },
                
                # 1.010 start/stop
                "010" => { :use => "G",
                    :name => "DPT_Start", 
                    :desc => "start/stop", 
                    :data_desc => { 0 => "Stop", 1 => "Start" }
                },
                
                # 1.011 state
                "011" => { :use => "FB",
                    :name => "DPT_State", 
                    :desc => "state", 
                    :data_desc => { 0 => "Inactive", 1 => "Active" }
                },
                
                # 1.012 invert
                "012" => { :use => "FB",
                    :name => "DPT_Invert", 
                    :desc => "invert", 
                    :data_desc => { 0 => "Not inverted", 1 => "inverted" }
                },
                
                # 1.013 dim send style
                "013" => { :use => "FB",
                    :name => "DPT_DimSendStyle", 
                    :desc => "dim send style", 
                    :data_desc => { 0 => "Start/stop", 1 => "Cyclically" }
                },
                
                # 1.014 input source
                "014" => { :use => "FB",
                    :name => "DPT_InputSource", 
                    :desc => "input source", 
                    :data_desc => { 0 => "Fixed", 1 => "Calculated" }
                },
                
                # 1.015 reset
                "015" => { :use => "G",
                    :name => "DPT_Reset", 
                    :desc => "reset",  
                    :data_desc => { 0 => "no action(dummy)", 1 => "reset command(trigger)" }
                },
                
                # 1.016 acknowledge
                "016" => { :use => "G",
                    :name => "DPT_Ack", 
                    :desc => "ack",  
                    :data_desc => { 0 => "no action(dummy)", 1 => "acknowledge command(trigger)" }
                },
                
                # 1.017 trigger
                "017" => { :use => "G",
                    :name => "DPT_Trigger", 
                    :desc => "trigger", 
                    :data_desc => { 0 => "trigger", 1 => "trigger" }
                },
                
                # 1.018 occupied
                "018" => { :use => "G",
                    :name => "DPT_Occupancy", 
                    :desc => "occupancy", 
                    :data_desc => { 0 => "not occupied", 1 => "occupied" }
                },
                
                # 1.019 open window or door
                "019" => { :use => "G",
                    :name => "DPT_WindowDoor", 
                    :desc => "open window/door", 
                    :data_desc => { 0 => "closed", 1 => "open" }
                },
                
                # 1.021 and/or
                "021" => { :use => "FB",
                    :name => "DPT_LogicalFunction", 
                    :desc => "and/or", 
                    :data_desc => { 0 => "logical function OR", 1 => "logical function AND" }
                },
                
                # 1.022 scene A/B
                "022" => { :use => "FB",
                    :name => "DPT_Scene_AB", 
                    :desc => "scene A/B", 
                    :data_desc => { 0 => "scene A", 1 => "scene B" }
                },
                
                # 1.023 shutter/blinds mode
                "023" => { :use => "FB",
                    :name => "DPT_ShutterBlinds_Mode", 
                    :desc => "shutter/blinds mode", 
                    :data_desc => { 0 => "only move Up/Down mode (shutter)", 1 => "move Up/Down + StepStop mode (blind)" }
                },
                
                # 1.100 cooling/heating     ---FIXME---
                "100" => {  :use => "???",
                    :name => "DPT_Heat/Cool", 
                    :desc => "heat/cool",
                    :data_desc => { 0 => "???", 1 => "???" }
                },
            }
        
        end #class
        
    end
    
end
