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

require 'rubygems'
require 'onstomp'

require 'ansible_utils'

module Ansible
    
    # Generic Ansible tranceiver
    # spawns a Ruby thread to call run()
    class Transceiver
        
        attr_reader :thread
        
        def initialize()
            begin
                @thread = Thread.new {
                    begin
                        run()
                    rescue Exception => e
                        puts "----#{self.class.name.upcase} EXCEPTION: #{e} ----"
                        puts "backtrace:\n\t" + e.backtrace.join("\n\t")
                    end
                }
            rescue Exception => e
                puts("Cannot spawn worker thread, #{e}")
                puts("backtrace:\n\t" << e.backtrace.join("\n\t"))
                exit(-1)
            end
        end
        
        def run
            raise "Must override Tranceiver.run() method!!!"
        end
        
        def stop()
            @thread.stop
        end
             
        attr_reader :all_devices
   
    end
    
end        