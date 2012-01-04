require 'bit-struct'

# 2-bit control value
class KNX_DPT2 < BitStruct
    unsigned :rest, 6
    unsigned :priority, 1, "1=Priority"
    unsigned :value, 1, "Value"
end

=begin
puts KNX_DPT2.bit_length
puts KNX_DPT2.new([0x00].pack('c')).inspect #
puts KNX_DPT2.new([0x01].pack('c')).inspect #
puts KNX_DPT2.new([0x02].pack('c')).inspect #
puts KNX_DPT2.new([0x03].pack('c')).inspect #

puts [0x02].pack('c').inspect
=begin
2.001 switch control
2.002 boolean control
2.003 enable control
2.004 ramp control
2.005 alarm control
2.006 binary value control
2.007 step control
2.010 start control
2.011 state control
2.012 invert control
=end