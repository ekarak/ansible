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

require 'ansible_value'

class Test
    include AnsibleValue
    
    def initialize(h)
        h.each{|k,v|
            puts "new iv #{k}=#{v}"
            instance_eval("@#{k} = v")
        }
    end
end


t = Test.new(:name => "Elias", :phone => 2108047860)
t2 = Test.new(:name => "Elina", :phone => 2103266682)

puts t.matches?(:name => /Chris/)
puts t.matches?(:name => /Chris/, :phone => /2108047860/)
puts t.matches?(:name => /Elias/)
puts t.matches?(:name => /Elias/, :phone => /2109832374/)
puts t.matches?(:name => /Elias/, :phone => /2108047860/)
puts '----'
puts AnsibleValue[:name => /Elias/]
puts '----^^ 1.should NOT find it'
AnsibleValue[[:name]] = t
puts '----'
puts AnsibleValue[:name => /Elias/]
puts '----^^ 2.should FIND it'
puts AnsibleValue[:name => /Elias/, :phone => /210/]
puts '----^^ 3.should NOT find it'
puts AnsibleValue[:name => /Elias/, :phone => /697/]
puts '----^^ 4.should NOT find it'
# try to put it again
AnsibleValue[[:name, :phone]] = t
puts '----'
puts AnsibleValue[:name => /Elias/, :phone => /210/]
puts '----^^ 5.should FIND it'
puts AnsibleValue[:name => /Elias/, :phone => /697/]
puts '----^^ 6.should NOT find it'
