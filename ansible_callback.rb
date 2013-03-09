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

require 'weakref'

module Ansible

    #
    # Callback module for project Ansible
    #    
    module AnsibleCallback
    
        
        # callback declaration mechanism.
        #
        # ===Arguments:
        # [event]   a Symbol for the event (eg :onChange) 
        #           A special case is :default , this callback gets called at all events.
        # [target]  a unique hashable target (so as to register a target-specific callback
        #           for an event) - you can pass any value, if it can be hashed. 
        #           TODO: use WeakRef,so that the target can be reclaimed by Ruby's GC 
        #           when its fixed on Ruby1.9 (http://bugs.ruby-lang.org/issues/4168)
        # [cb_body] the Proc to call when a callback is fired.
        #
        # the callback Proc block always gets these arguments supplied:
        # [obj]   1st argument to callback proc is the AnsibleValue instance 
        #         which generated the callback
        # [cb]    2nd argument is the callback symbol (eg :onChange)
        #         Very useful when declaring a default callback
        # [*args] 3rd and later arguments: event-specific data
        #
        # examples:
        #   obj.add_callback(:onChange) { |o| puts "Object #{o} has changed!" }
        #   obj.add_callback(:onChange, 'SPECIAL') { |o| puts "Object #{o} has changed!" }
        #   obj.add_callback(:default) { |o, cb, *args| puts "Object #{o}: callback #{cb}!" }
        def add_callback(event, target=nil, &cb_body)
            raise "add_callback: last argument must be a Proc" unless cb_body.is_a?Proc
            init_callbacks(event)
            puts "#{self}: Registering #{event} callback" + (target.nil? ? '' : " especially for target #{target}")
            if target.nil? then
                @callbacks[event].default = cb_body
            else
                @callbacks[event][target] = cb_body
            end
        end
        
        # remove a callback
        #
        # ===Arguments:
        # [event]    a Symbol for the event (eg :onChange) 
        #            A special case is :default , this callback gets called at all events.
        # [target]   a unique hashable target - you can pass any value
        #
        # ===Examples:
        #   obj.remove_callback(:onUpdate)
        def remove_callback(event, target=nil)
            init_callbacks(event)
            @callbacks[event].delete(target)
        end
        
        # callback firing processor.
        #
        # Checks if a proc is stored for a ginen event, then calls it
        # with the object instance as its first argument,  the callback symbol 
        # as its second arg, and all other *args appended to the call
        #
        # ===Arguments:
        # [event]    a Symbol for the event (eg :onChange) 
        # [target]  the unique id of target (so as to fire target-specific callbacks for a specific event)
        #        
        # ===Notes:
        # 1) its prohibited to fire the DEFAULT callback programmatically (it will get fired 
        # anyway at ANY event)
        # 2) if a target_id is given, then try to fire target-specific callbacks. If none is found,
        # fall-back to the generic callback for this event
        #
        # ===Example:
        #   obj.fire_callback(:onChange, 'GROUPADDR', :arg1, :arg2, :arg3)
        #
        def fire_callback(event, target=nil, *args)
            raise "cannot fire DEFAULT callback programmatically!" if event.to_s == "default"
            #puts "fire_callback called by #{self}.#{event}, args: #{args.inspect}"
            init_callbacks(event)
            # array of callback Procs to get called
            cb_procs = []
            # first add callbacks for this specific event
            if defined?(@callbacks) and @callbacks.is_a?Hash then
                [@callbacks[event],  @callbacks[:default]].each { |hsh|
                    if hsh.is_a?Hash then
                        #puts "#{self}.fire_callback, event #{event}: about to fire: #{hsh.inspect}"
                        if target.nil? then 
                            # add all targets to the list of procs to call
                            # including the default 
                            cb_procs << [hsh.values, hsh.default].flatten
                        else
                            # only add target-specific procs to the list
                            cb_procs << hsh[target]
                        end
                    end                    
                }
            end
            #puts cb_procs.inspect
            # time to fire callbacks 
            cb_procs.flatten.compact.each { |cb_proc|
                raise "ooops, found a #{cb_proc.class} stored as a callback!" unless cb_proc.is_a?Proc                    
                # puts "firing #{event} callback, args: #{args.inspect}" 
                cb_proc.call(self, event.to_s, *args)                    
            }
        end
        
        private
        # initialize callback hash for a given event
        def init_callbacks(event)
            md = caller[1].match(/`(\w*)'/); clr = md and md[1] or caller[1]
            raise "#{clr}: no event Symbol supplied!" unless event.is_a?Symbol
            @callbacks = {} unless defined?(@callbacks) and @callbacks.is_a?Hash
            @callbacks[event] = {} unless @callbacks[event].is_a?Hash            
        end
    end

end #module
