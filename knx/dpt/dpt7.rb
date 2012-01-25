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

#
# DPT7.*: 2-byte unsigned value
#

module Ansible
    
    module KNX
        
        module DPT7
            
            # Bitstruct to parse a DPT7 frame. 
            # Always 8-bit aligned.
            class FrameStruct < BinData::Record
                endian :big
                #
                uint16 :data, :display_name => "Value"
            end        
            
            # DPT basetype info
            Basetype = {
                :bitlength => 16,
                :valuetype => :basic,
                :desc => "16-bit unsigned value"
            }
            
            # DPT subtypes info
            Subtypes = {
                # 7.001 pulses
                
                # 7.003 time(10ms)
                # 7.004 time(100ms)
                # 7.005 time(s)
                # 7.006 time(min)
                # 7.007 time(h)
                # 7.012 current(mA)
                
                # 7.002 time(ms)               
                "002" => {
                    :name => "DPT_TimePeriodMsec", 
                    :desc => "time (ms)",
                    :unit => "milliseconds"
                },
                
                # 7.003 time (10ms)
                "003" => {
                    :name => "DPT_TimePeriod10Msec", 
                    :desc => "time (10ms)",
                    :unit => "centiseconds"
                },
                
                # 7.004 time (100ms)
                "004" => {
                    :name => "DPT_TimePeriod100Msec", 
                    :desc => "time (100ms)",
                    :unit => "deciseconds"
                },
                
                # 7.005 time (sec)
                "005" => {
                    :name => "DPT_TimePeriodSec", 
                    :desc => "time (s)",
                    :unit => "seconds"
                },
                
                # 8.006 time lag (min)
                "006" => {
                    :name => "DPT_TimePeriodMin", 
                    :desc => "time lag(min)",
                    :unit => "minutes"
                },
                
                # 8.007 time lag (hour)
                "007" => {
                    :name => "DPT_TimePeriodHrs", 
                    :desc => "time lag(hrs)",
                    :unit => "hours"
                },

            }
         end

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