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

module AnsibleValue

    attr_reader :previous_value, :current_value
    attr_reader :last_update
    
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
                when Array then filter.include?(val)
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
    
    # update internal instance variable representing the current state of the value 
    def update(newval)
        unless @current_value == newval then
            @last_update = Time.now
            puts "==> updating value #{self}, with #{newval.inspect}"        
            # previous value was different, update it and fire onUpdate handler
            @previous_value = @current_value
            @current_value = newval
            # trigger onUpdate callback, if any
            fire_callback(:onUpdate, @current_value)
        end
    end

end #module