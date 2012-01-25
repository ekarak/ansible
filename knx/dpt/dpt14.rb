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
        # DPT14.*: 4-byte floating point value
        #
        module DPT14

            # special Bindata::Primitive class required 
            # for non-standard 32-bit floats used by DPT14
            class DPT14_Float < BinData::Primitive
                endian :big
                #
                bit1  :sign, :display_name => "Sign"
                bit8  :exp,  :display_name => "Exponent"
                bit23 :mant, :display_name => "Mantissa"
                #
                def get
                    # puts "sign=#{sign} exp=#{exp} mant=#{mant}"
                    mantissa = (self.sign==1) ? ~(self.mant^8388607) : self.mant
                    return Math.ldexp(mantissa, self.exp)
                end
                #
                #DPT9_Range = -671088.64..670760.96
                #
                def set(v)
                    #raise "Value (#{v}) out of range" unless DPT9_Range === v
                    mantissa, exponent = Math.frexp(v)
                    #puts "#{self}.set(#{v}) with initial mantissa=#{mantissa}, exponent=#{exponent}"
                    # find the minimum exponent that will upsize the normalized mantissa (0,5 to 1 range)
                    # in order to fit in 11 bits (-2048..2047)
                    max_mantissa = 0
                    minimum_exp = exponent.downto(-127).find{ | e |
                        max_mantissa = Math.ldexp(100*mantissa, e).to_i
                        max_mantissa.between?(-8388608, 8388607)
                    } 
                    self.sign = (mantissa < 0) ?  1 :  0 
                    self.mant  = (mantissa < 0) ?  ~(max_mantissa^8388607) : max_mantissa 
                    self.exp = exponent - minimum_exp  
                end # set
            end

            # Bitstruct to parse a DPT9 frame. 
            # Always 8-bit aligned.
            class FrameStruct < BinData::Record
                dpt14_float :data
            end

            # DPT14 base type info
            Basetype = {
                :bitlength => 32,
                :valuetype => :basic,
                :desc => "32-bit floating point value"
            }
            
            # DPT14 subtypes info
            Subtypes = {
                # TODO: so fucking many of them!
            }
        end
    end
end
