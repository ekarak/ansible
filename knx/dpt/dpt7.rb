require 'bit-struct'

# 2-byte unsigned value
class KNX_DPT7 < BitStruct
    unsigned :value, 16, "Value"
end
=begin
puts KNX_DPT2.bit_length
puts KNX_DPT2.new([0x00].pack('c')).inspect #
puts KNX_DPT2.new([0x01].pack('c')).inspect #
puts KNX_DPT2.new([0x02].pack('c')).inspect #
puts KNX_DPT2.new([0x03].pack('c')).inspect #

puts [0x02].pack('c').inspect

=begin
7.001 pulses
7.002 time(ms)
7.003 time(10ms)
7.004 time(100ms)
7.005 time(s)
7.006 time(min)
7.007 time(h)
7.012 current(mA)
=end