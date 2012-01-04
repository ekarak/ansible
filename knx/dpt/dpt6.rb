require 'bit-struct'

# 8-bit signed value
class KNX_DPT6 < BitStruct
    unsigned :sign, 1, "Sign"
    unsigned :value, 7, "Value"
end
=begin
puts KNX_DPT6.bit_length
puts KNX_DPT6.new([0x32].pack('c')).inspect # 50
puts KNX_DPT6.new([0xce].pack('c')).inspect # -50
=begin
6.001 percentage (-128%..127%)
6.002 counter pulses (-128..127)
=end