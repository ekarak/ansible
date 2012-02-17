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

module Ansible
        
    # a CommandChain is a graph describing the sequence 
    # of inputs, outputs and status values for an Ansible Device 
    class CommandChain
        
        # initialize an empty command chain
        def initialize()
            @inputs, @outputs, @statuses = [], [], []
        end
        
        #
        # add an input value
        def input(value)
            raise "add_input: #{value} must be an AnsibleValue!" unless value.is_a? AnsibleValue
            puts "#{self.class}: adding input value #{value}"
            @inputs << value unless @inputs.include?(value)
            return self # so as to chain multiple calls
        end #def

        #
        # add an output value
        def output(value)
            raise "add_output: #{value} must be an AnsibleValue!" unless value.is_a? AnsibleValue
            raise "add_output: #{value} is already declared as input!" if @inputs.include?(value)            
            puts "#{self.class}: adding output value #{value}"
            @outputs << value unless @outputs.include?(value)
            return self # so as to chain multiple calls
        end #def
        
        #
        # add a status feedback value
        def status(value)
            raise "add_status: #{value} must be an AnsibleValue!" unless value.is_a? AnsibleValue
            raise "add_status: #{value} is already declared as output!" if @outputs.include?(value)
            puts "#{self.class}: adding status value #{value}"
            @statuses << value unless @statuses.include?(value)
            return self # so as to chain multiple calls
        end

        def link(source, target)
            raise "link: both arguments must be AnsibleValues!" if [source,target].find{|v| not v.is_a?AnsibleValue}
            source.add_callback(:onUpdate, self) { |sender, cb, args| 
                puts "(#{sender.class}) #{sender} input value updated! args=#{args}"
                #convert value domains 
                cv = sender.as_canonical_value
                newval = output.to_protocol_value(cv)
                puts "+++ setting output #{output} +++ cv=#{cv} newval=#{newval}"
                target.set(newval)            
            }
        end
        
        def bind_all
            puts "#{self}: binding all values"
            @inputs.each { |input|
                
            }
            return self
        end        
    end
    
                    
    class AbstractDevice
    
        #
        def initialize(state_value)
            raise "add_status: #{value} must be an AnsibleValue!" unless value.is_a? AnsibleValue
            @state_value = state_value
        end
        

    end
        
    
    #
    # load all known Ansible Device classes
    Dir["devices/*.rb"].each { |f| load f }

end
