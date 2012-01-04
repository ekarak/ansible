require 'bit-struct'

# 8-bit character
class KNX_DPT4 < BitStruct
    char :value, 8, "Character"
end
=begin
puts KNX_DPT2.bit_length
puts KNX_DPT2.new([0x00].pack('c')).inspect #
puts KNX_DPT2.new([0x01].pack('c')).inspect #
puts KNX_DPT2.new([0x02].pack('c')).inspect #
puts KNX_DPT2.new([0x03].pack('c')).inspect #

puts [0x02].pack('c').inspect

=begin
4.001 character (ASCII)
4.002 character (ISO-8859-1)
=end