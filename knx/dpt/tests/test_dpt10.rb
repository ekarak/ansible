require 'bindata'

class DPT10 < BinData::Record
    bit3 :dayofweek, {
        :display_name => "Day of week", 
        :range => 0..7, :data_desc => {
            0 => "(no day set)",
            1 => "Monday",
            2 => "Tuesday",
            3 => "Wednesday",
            4 => "Thursday",
            5 => "Friday",
            6 => "Saturday",
            7 => "Sunday"
        }    
    }
    bit5 :hour,      {
        :display_name =>  "Hour", :range => 0..23
    }
    #
    bit2 :unused1
    bit6 :minutes,   {
        :display_name =>  "Minutes", :range => 0..59
    }
    #
    bit2 :unused2
    bit6 :seconds,  {
        :display_name =>  "Seconds", :range => 0..59
    }
end
[
    [0x8e, 0x21, 0x00]
].each {|arr|
    f = DPT10.read(arr.pack('C*'))
    puts arr.inspect + " ==> " + f.inspect
#    f.data = -10
 #   puts "after set() ==> " + f.inspect + " serialized as " + f.to_binary_s.unpack("H*").join('0x')  
 #f.dayofweek.get_parameter(:range)
}
=begin
[
    # DPT11.001 date
    [0x17, 0x01, 0x0C] # 23/Jan/2012
].each {|arr|
=end