require 'bit-struct'

# 2-byte floating point value
class KNX_DPT9 < BitStruct
    unsigned :sign,     1,  "Sign"
    unsigned :exp,      4,  "Exponent"
    unsigned :mant,    11, "Mantissa"
    def floating_value
        mantissa = (self.sign==1) ? ~self.mant : self.mant
        puts "mantissa=#{mantissa.to_s(2)}"
        return Math.ldexp((0.01*mantissa), self.exp)
    end
end

=begin
def testdpt9(value)
    puts "Testing DPT9 value: #{value.inspect}"
    v =KNX_DPT9.new(value)
    puts v.inspect
    puts v.floating_value
end

testdpt9 [0x14, 0xE2].pack('c*') # -30
testdpt9 [0x8a, 0x24].pack('c*') # -30
testdpt9 [0x93, 0x1e].pack('c*') # -50
testdpt9 [0x5c, 0xc4].pack('c*') # 25000
testdpt9 [0xdb, 0x3c].pack('c*') # -25000

#testdpt9 [0b1000101000100100].pack('n')     
=begin
9.001 temperature (oC)
9.002 temperature difference (oC)
9.003 kelvin/hour (K/h)
9.004 lux (Lux)
9.005 speed (m/s)
9.006 pressure (Pa)
9.007 percentage (%)
9.008 parts/million (ppm)
9.010 time (s)
9.011 time (ms)
9.020 voltage (mV)
9.021 current (mA)
9.022 power density (W/m2)
9.023 kelvin/percent (K/%)
9.024 power (kW)
9.025 volume flow (l/h)
9.026 rain amount (l/m2)
9.027 temperature (oF)
9.028 wind speed (km/h)
=end
