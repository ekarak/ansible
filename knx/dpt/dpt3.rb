=begin

require 'knx_value'

class DPT3_Value < KNXValue
    def initialize(data)
        @data = data
    end
end

class DPT3_Control_Value < DPT3_Value
    def parse
    end
=end


require 'bit-struct'

# 4 bit relative dimmer control
class KNX_DPT3_Control < BitStruct
    unsigned    :rest,          4
    unsigned    :incr_bit,       1, "Decrease(0) / Increase(1)"
    unsigned    :stepcode,   3, "0=break, 1-7 = 1 to 100%"
end
    
#~ data="\xE9".to_i(16)
#~ puts (data & 0x0f)

=begin
        2.6.3.5 Behavior
Status
off     dimming actuator switched off
on      dimming actuator switched on, constant brightness, at least
        minimal brightness dimming
dimming actuator switched on, moving from actual value in direction of
        set value
Events
    position = 0        off command
    position = 1        on command
    control = up dX     command, dX more bright dimming
    control = down dX   command, dX less bright dimming
    control = stop      stop command
    value = 0           dimming value = off
    value = x%          dimming value = x% (not zero)
    value_reached       actual value reached set value

The step size dX for up and down dimming may be 1/1, 1/2, 1/4, 1/8, 1/16, 1/32 and 1/64 of
the full dimming range (0 - FFh).

=end

class KNX_DPT3_Value < BitStruct
    unsigned :absvalue, 8, "Absolute Value 1(1%) - 255(100%)"
end

=begin
3.007 dimming control
3.008 blind control
=end