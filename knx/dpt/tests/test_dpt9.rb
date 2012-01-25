require 'bindata'

class DPT9_Float < BinData::Primitive
    endian :big
    #
    bit1 :sign,  :display_name =>  "Sign"
    bit4 :exp,   :display_name => "Exponent"
    bit11 :mant,   :display_name => "Mantissa"
    #
    def get
        puts "get, sign=#{sign} exp=#{exp} mant=#{mant}"
        mantissa = (self.sign==1) ? ~(self.mant^2047) : self.mant
        return Math.ldexp((0.01*mantissa), self.exp)
    end
    #
    def set(v)
        mantissa, exponent = Math.frexp(v)
        puts "#{self}.set(#{v}) with initial mantissa=#{mantissa}, exponent=#{exponent}"
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
        puts "... set(#{v}) finished: sign=#{sign}, mantissa=#{mant}, exponent=#{exp}"
    end # set
end

class DPT9 < BinData::Record
    dpt9_float :data
end

{
#forward test (raw data to float)
    DPT9.read([0x00, 0x02].pack('C*')).data => 0.02,
    DPT9.read([0x87, 0xfe].pack('C*')).data => -0.02,
    DPT9.read([0x5c, 0xc4].pack('C*')).data => 24980..25000,
    DPT9.read([0xdb, 0x3c].pack('C*')).data => -25000..-24980,
    DPT9.read([0x7f, 0xfe].pack('C*')).data => 670400..670760,
    DPT9.read([0xf8, 0x02].pack('C*')).data => -670760..-670400,
#backward test (float to raw data)
    "----" => "----",
    DPT9_Float.new(0.02).to_binary_s.unpack("C*") =>  [0x00, 0x02],
    DPT9_Float.new(-0.02).to_binary_s.unpack("C*") =>  [0x87, 0xfe],
    DPT9_Float.new(25000).to_binary_s.unpack("C*") =>  [0x5c, 0xc4],
    DPT9_Float.new(-25000).to_binary_s.unpack("C*") =>  [0xdb, 0x3c],
    DPT9_Float.new(670760).to_binary_s.unpack("C*") =>  [0x7f, 0xfe],
    DPT9_Float.new(-670760).to_binary_s.unpack("C*") =>  [0xf8, 0x02],
}.each {|arr, test|
    #f = DPT9.read(arr.pack('C*'))
    puts arr.inspect + " ==> " + test.inspect + " \t TEST: " + (test === arr ? 'ok':"\t---FAIL---")
#    f.data = -30
#    puts "after set() ==> " + f.inspect + " serialized as " + f.to_binary_s.unpack('B*').join(' ') + " (0x" + f.to_binary_s.unpack("H*").join('') + ")"
}


