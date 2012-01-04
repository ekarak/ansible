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

module AnsibleCallback

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
    #   obj.declare_callback(:default) { |o, cb| puts "Object #{o}: callback #{cb}!" }
    def declare_callback(cb, &cb_body)
        raise "declare_callback: 1st argument must be a Symbol" unless cb.is_a?Symbol
        raise "declare_callback: 2nd argument must be a Proc" unless cb_body.is_a?Proc
        @callbacks = {} if @callbacks.nil?
        if (cb.to_s[0..1] == "on")  then
            puts "Registering callback  (#{cb}) for #{self.inspect}"
            @callbacks[cb] = cb_body
        elsif (cb.to_s == "default") then
            puts "Registering DEFAULT callback  for #{self.inspect}"
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
            puts "firing callback(#{cb}) args: #{args.inspect}" if $DEBUG
            cb_proc .call(self, cb.to_s, *args)
        else
            #puts "WARNING: callback #{cb} not found for #{self}, iv=#{iv} cb_proc=#{cb_proc.inspect}"
        end
    end
    
end #module
