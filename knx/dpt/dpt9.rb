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

require 'bindata'

module Ansible
    
    module KNX
        
        #
        # DPT9.*: 2-byte floating point value
        #        
        module DPT9
    
            # special Bindata::Primitive class required 
            # for non-standard 16-bit floats used by DPT9
            class DPT9_Float < BinData::Primitive
                endian :big
                #
                bit1 :sign,  :display_name =>  "Sign"
                bit4 :exp,   :display_name => "Exponent"
                bit11 :mant,   :display_name => "Mantissa"
                #
                def get
                    # puts "sign=#{sign} exp=#{exp} mant=#{mant}"
                    mantissa = (self.sign==1) ? ~(self.mant^2047) : self.mant
                    return Math.ldexp((0.01*mantissa), self.exp)
                end
                #
                DPT9_Range = -671088.64..670760.96
                #
                def set(v)
                    raise "Value (#{v}) out of range" unless DPT9_Range === v
                    mantissa, exponent = Math.frexp(v)
                    #puts "#{self}.set(#{v}) with initial mantissa=#{mantissa}, exponent=#{exponent}"
                    # find the minimum exponent that will upsize the normalized mantissa (0,5 to 1 range)
                    # in order to fit in 11 bits (-2048..2047)
                    max_mantissa = 0
                    minimum_exp = exponent.downto(-15).find{ | e |
                        max_mantissa = Math.ldexp(100*mantissa, e).to_i
                        max_mantissa.between?(-2048, 2047)
                    } 
                    self.sign = (mantissa < 0) ?  1 :  0 
                    self.mant  = (mantissa < 0) ?  ~(max_mantissa^2047) : max_mantissa 
                    self.exp = exponent - minimum_exp  
                end # set
            end

            # Bitstruct to parse a DPT9 frame. 
            # Always 8-bit aligned.
            class FrameStruct < BinData::Record
                dpt9_float :data
            end
        
            # DPT9 basetype info
            Basetype = {
                :bitlength => 16,
                :valuetype => :basic,
                :desc => "16-bit floating point value"
            }
            
            # DPT9 subtypes
            Subtypes = {    
                # 9.001 temperature (oC)
                "001" => {
                    :name => "DPT_Value_Temp", :desc => "temperature", 
                    :unit => "°C", :range => -273..670760
                },
                
                # 9.002 temperature difference (oC)
                "002" => {
                    :name => "DPT_Value_Tempd", :desc => "temperature difference", 
                    :unit => "°C", :range => -670760..670760
                },

                # 9.003 kelvin/hour (K/h)
                "003" => {
                    :name => "DPT_Value_Tempa", :desc => "kelvin/hour", 
                    :unit => "°K/h", :range => -670760..670760
                },

                # 9.004 lux (Lux)
                "004" => {
                    :name => "DPT_Value_Lux", :desc => "lux", 
                    :unit => " lux", :range => 0..670760
                },
                
                # 9.005 speed (m/s)
                "005" => {
                    :name => "DPT_Value_Wsp", :desc => "wind speed", 
                    :unit => "m/s", :range => 0..670760
                },
                
                # 9.006 pressure (Pa)
                "006" => {
                    :name => "DPT_Value_Pres", :desc => "pressure", 
                    :unit => "Pa", :range => 0..670760
                },
                
                # 9.007 humidity (%)
                "007" => {
                    :name => "DPT_Value_Humidity", :desc => "humidity", 
                    :unit => "%", :range => 0..670760
                },
                
                # 9.008 parts/million (ppm)
                "008" => {
                    :name => "DPT_Value_AirQuality", :desc => "air quality", 
                    :unit => "ppm", :range => 0..670760
                },
                
                # 9.010 time (s)
                "010" => {
                    :name => "DPT_Value_Time1", :desc => "time(sec)", 
                    :unit => "s", :range => -670760..670760
                },
                
                # 9.011 time (ms)
                "011" => {
                    :name => "DPT_Value_Time2", :desc => "time(msec)", 
                    :unit => "ms", :range => -670760..670760
                },
                
                # 9.020 voltage (mV)
                "020" => {
                    :name => "DPT_Value_Volt", :desc => "voltage", 
                    :unit => "mV", :range => -670760..670760
                },
                
                # 9.021 current (mA)
                "021"  => {
                    :name => "DPT_Value_Curr", :desc => "current", 
                    :unit => "mA", :range => -670760..670760
                },
                
                # 9.022 power density (W/m2)
                "022" => {
                    :name => "DPT_PowerDensity", :desc => "power density", 
                    :unit => "W/m²", :range => -670760..670760
                },
                
                # 9.023 kelvin/percent (K/%)
                "023" => {
                    :name => "DPT_KelvinPerPercent", :desc => "Kelvin / %", 
                    :unit => "K/%", :range => -670760..670760
                },
                
                # 9.024 power (kW)
                "024" => {
                    :name => "DPT_Power", :desc => "power (kW)", 
                    :unit => "kW", :range => -670760..670760
                },
                
                # 9.025 volume flow (l/h)
                "025" => {
                    :name => "DPT_Value_Volume_Flow", :desc => "volume flow", 
                    :unit => "l/h", :range => -670760..670760
                },
                
                # 9.026 rain amount (l/m2)
                "026" => {
                    :name => "DPT_Rain_Amount", :desc => "rain amount", 
                    :unit => "l/m²", :range => -670760..670760
                },
                
                # 9.027 temperature (Fahrenheit)
                "027" => {
                    :name => "DPT_Value_Temp_F", :desc => "temperature (F)", 
                    :unit => "°F", :range => -459.6..670760
                },
                
                # 9.028 wind speed (km/h)
                "028" => {
                    :name => "DPT_Value_Wsp_kmh", :desc => "wind speed (km/h)", 
                    :unit => "km/h", :range => 0..670760
                },
            }

        end

    end
    
end

