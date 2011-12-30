#~ Project Ansible
#~ (c) 2011 Elias Karakoulakis <elias.karakoulakis@gmail.com>

module AnsibleValue

    attr_reader :previous_value, :current_value
    attr_accessor :callbacks
    
    # return true if a value's instance variable (whose symbol is iv_symbol) matches a filter value (as a regexp)
    # e.g. value.matches?(:name => /elias/, :telephone => /210/)
    def matches?(hash)
        raise "#{self.class}: AnsibleValue.match? single argument must be a hash.." unless hash.is_a?Hash
        result = true
        hash.each { |iv_symbol, filter|
            raise "#{self.class}: AnsibleValue.match?(hash)'s keys must be Symbols.." unless iv_symbol.is_a?Symbol
            if val = instance_eval('@'+iv_symbol.to_s) then
                #puts "match.val(#{iv_symbol}) == #{val}"
                result = result & case filter
                when Regexp then filter.match(val.to_s)
                else filter == val
                end
            else
                return false
            end
        }
        return(result)
    end
    
    # singleton array of all known Values
    @@AllValues = []

    # lookup an AnsibleValue by a filter hash
    def AnsibleValue.[](filter_hash)
        #puts "AnsibleValue[] called, filter_hash=#{filter_hash}"
        result_set = nil
        @@AllValues.each { |v|
            raise "ooops! @@AllValues contains a non-AnsibleValue!" unless v.is_a?(AnsibleValue)
            if v.matches?(filter_hash) then
                puts "Found a matching value! #{v}" if $DEBUG
                result_set = Array.new unless result_set.is_a?Array
                result_set << v
            end
        }
        return result_set
    end
    
    #
    # add an AnsibleValue to the singleton @@AllValues
    # returns the newvalue
    def AnsibleValue.insert(newvalue)
        if @@AllValues.include?(newvalue) then
            # newvalue is already stored in @@AllValues, find it and return it
            return( @@AllValues.find{|val| val == newvalue} )
        else
            puts "Adding a new value to @@AllValues (#{newvalue})" if $DEBUG
            @@AllValues << newvalue
            # get initial state
            newvalue.get
            return(newvalue)
        end
    end
    
    #
    # CALLBACKS
    #
    
    # callback declaration mechanism.
    # callbacks must be defined by a Symbol (eg :onChange) starting with "on" 
    # A special case is :default , this callback gets called at all events.
    # the callback Proc always gets supplied these arguments
    # 1st argument to callback proc is the ValueID instance
    # 2nd argument is the callback symbol (eg :onChange)
    # 3rd and later arguments: event-specific data
    # example:
    #   obj.declare_callback(:onChange) { |o| puts "Object #{o} has changed!" }
    #   obj.declare_callback(:default) { |o, cb| puts "Object #{o} callback #{cb}!" }
    def declare_callback(cb, &cb_body)
        raise "declare_callback: 1st argument must be a Symbol" unless cb.is_a?Symbol
        raise "declare_callback: 2nd argument must be a Proc" unless cb_body.is_a?Proc
        @callbacks = {} unless @callbacks.is_a?Hash
        if (cb.to_s[0..1] == "on")  then
            puts "Registering callback  (#{cb}) for #{self}"
            @callbacks[cb] = cb_body
        elsif (cb.to_s == "default") then
            puts "Registering DEFAULT callback  for #{self}"
            @callbacks.default = cb_body
        end
    end
    
    # callback firing processor. 
    # Checks if a proc is stored as an instance variable, then calls it
    # with the object instance as its first argument,  the callback symbol 
    # as its second arg, and all other *args appended to the call
    # example:
    #   obj.fire_callback(:onChange, :arg1, :arg2, :arg3)
    def fire_callback(cb, *args)
        raise "fire_callback: 1st argument must be a Symbol" unless cb.is_a?Symbol
        @callbacks = {} unless @callbacks.is_a?Hash
        default = @callbacks.has_key?(cb)
        if (cb_proc = @callbacks[cb]).is_a?Proc then
            puts "firing callback(#{cb}) args: #{args.inspect}"
            cb_proc .call(self, cb.to_s, *args)
        else
            #puts "WARNING: callback #{cb} not found for #{self}, iv=#{iv} cb_proc=#{cb_proc.inspect}"
        end
    end
        

end #module