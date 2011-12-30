#~ Project Ansible
#~ (c) 2011 Elias Karakoulakis <elias.karakoulakis@gmail.com>

# various KNX tool functions

# addr2str: Convert an integer to an EIB address string, in the form "1/2/3" or "1.2.3"
def addr2str(a, ga=false)
    str=""
    if a.is_a?Array then
        #~ a = a[0]*256+a[1]
        a = a.pack('c*').unpack('n')[0]
    end
    if (ga)
        str = "#{(a >> 11) & 0xf}/#{(a >> 8) & 0x7}/#{a & 0xff}"
    else
        str = "#{a >> 12}.#{(a >> 8) & 0xf}.#{a & 0xff}"
    end
    return(str)
end

# str2addr: Parse an address string into an unsigned 16-bit integer
def str2addr(s)
    if m = s.match(/(\d*)\/(\d*)\/(\d*)/)
        a, b, c = m[1].to_i, m[2].to_i, m[3].to_i
        return ((a & 0x01f) << 11) | ((b & 0x07) << 8) | ((c & 0xff))
    end
    if m = s.match(/(\d*)\/(\d*)/)
        a,b = m[1].to_i, m[2].to_i
        return ((a & 0x01f) << 11) | ((b & 0x7FF))
    end
    if s.start_with?("0x")
        return (s.to_i & 0xffff)
    end
end


#ga = 17*256 + 200
#~ ga = [17, 200]
#~ puts(addr2str(ga))
#~ dest= str2addr("1/2/0")