=begin
Project Ansible  - An extensible home automation scripting framework
----------------------------------------------------
Copyright (c) 2011 Elias Karakoulakis <elias.karakoulakis@gmail.com>

SOFTWARE NOTICE AND LICENSE

Project Ansible is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

Project Ansible is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Project Ansible.  If not, see <http://www.gnu.org/licenses/>.

for more information on the LGPL, see:
http://en.wikipedia.org/wiki/GNU_Lesser_General_Public_License
=end

require 'ansible_callback'

module Ansible
    
    # A base module for Ansible Values, which is the most basic form to declare a
    # protocol-agnostic control endpoint, be it an input (a button or event), or
    # an output (a device such as a relay or dimmer)
    module AnsibleValue
    
    include AnsibleCallback
    
    attr_reader :previous_value, :current_value
    attr_reader :last_update
    attr_reader :flags
    
    # return true if a value's instance variable (whose symbol is iv_symbol) matches a filter value (as a regexp)
    # e.g. value.matches?(:name => /elias/, :telephone => /210/)
    def matches?(hash)
        raise "#{self.class}: AnsibleValue.match? single argument must be a hash.." unless hash.is_a?Hash
        result = true 
        hash.each { |iv_symbol, filter|
            raise "#{self.class}: AnsibleValue.match?(hash)'s keys must be Symbols.." unless iv_symbol.is_a?Symbol
            if respond_to?(iv_symbol) and (val = instance_eval(iv_symbol.to_s)) then
                #puts "match.val(#{iv_symbol}) == #{val.inspect}" if $DEBUG
                result = result & case filter
                # if the filter is a regular expression, use it to match the instance value
                when Regexp then filter.match(val.to_s)
                # if the filter is an array, use set intersection
                when Array then (filter & val).length > 0
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
    @@AllValuesMutex = Mutex.new

    # lookup an AnsibleValue by a filter hash
    # returns an array of matching values
    def AnsibleValue.[](filter_hash)
        result_set = []
        @@AllValuesMutex.synchronize {
            puts "AnsibleValue[] called, filter_hash=#{filter_hash}" if $DEBUG
            @@AllValues.each { |v|
                raise "ooops! @@AllValues contains a non-AnsibleValue!" unless v.is_a?(AnsibleValue)
                if v.matches?(filter_hash) then
                    puts "Found a matching value! #{v}" if $DEBUG
                    result_set << v
                end
            }
            puts "AnsibleValue[] returns=#{result_set}" if $DEBUG
        }
        return result_set
    end
    
    #
    # add an AnsibleValue to the singleton @@AllValues
    # returns the newvalue, or the existing value (using equality test ==), if found
    def AnsibleValue.insert(newvalue)
        result = nil
        @@AllValuesMutex.synchronize {
            # check if newvalue is already stored in @@AllValues, find it and return it
            if  (result = @@AllValues.find{|val| newvalue == val}).nil? then
                puts "Adding a new value to @@AllValues (#{newvalue})" if $DEBUG
                @@AllValues << (result = newvalue)
                # get initial state
                newvalue.get 
            end
        }
        return(result)
    end
    
    #
    # get a value's current state
    # returns: the value, if found in eibd's cache or nil otherwise
    def get
        return if write_only?
        #
        puts "get() called for #{self.inspect} by:\n\t" + caller[1] if $DEBUG
        #
        fire_callback(:onBeforeGet)
        if read_value() then 
            fire_callback(:onAfterGetSuccess)
        else
            fire_callback(:onAfterGetFail)
            #raise "get value failed for #{self}"
        end
    end

    #
    # set a value 
    # new_val: the new value, must be ruby-castable to OpenZWave's type system
    # returns: true on success, raises exception on error
    #WARNING: a true return value doesn't mean the command actually succeeded, 
    # it only means that it was queued for delivery to the target node
    def set(new_val)
        return if read_only?
        #
        puts "set() called for #{self.inspect} by:\n\t" + caller[1] if $DEBUG
        #
        fire_callback(:onBeforeSet)
        if write_value(new_val) then 
            fire_callback(:onSetSuccess)
        else
            fire_callback(:onSetFail)
            raise "set value #{self}: call to #{write_operation} failed!!"
        end
    end
    
    #
    # update internal instance variable representing the current state of the value
    # called by read_value() and write_value()
    def update(newval)
        validate_ranges() if respond_to?(:validate_ranges)
        unless newval == @current_value then
            @last_update = Time.now
            puts "+++ updating value #{self}, with #{newval.class}:#{newval.inspect}"
            
            # previous value was different, update it and fire onUpdate handler
            @previous_value = @current_value if defined?(@current_value)
            @current_value = newval
            # trigger onUpdate callback, if any
            fire_callback(:onUpdate, nil, newval)
        end
        return(@current_value)
    end

    # GENERICS
    # --------
                
    # write value to the protocol
    def write_value()
        raise "#{self.class}.write_value() must be overriden!!!"
    end
            
    # value convertion from protocol-specific to its canonical form
    # must be overriden by protocol value subclass
    def as_canonical_value()
        raise "#{self.class}.as_canonical_value() must be overriden!!!"
    end
    
    # convert a canonical value back to its protocol-specific form
    # must be overriden by protocol value subclass
    def to_protocol_value(v)
        raise "#{self.class}.to_protocol_value() must be overriden!!!"
    end
    
end

end #module