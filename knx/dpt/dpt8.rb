require 'bit-struct'

# 2-byte signed value
class KNX_DPT8 < BitStruct
    unsigned :value,    16, "Value"
end


=begin
8.001 pulses difference
8.002 time lag (ms)
8.003 time lag (10ms)
8.004 time lag (100ms)
8.005 time lag (sec)
8.006 time lag (min)
8.007 time lag (hour)
8.010 percentage difference (%)
8.011 rotation angle (deg)
=end