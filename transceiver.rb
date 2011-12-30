#~ Project Ansible
#~ (c) 2011 Elias Karakoulakis <elias.karakoulakis@gmail.com>

require 'rubygems'
require 'onstomp'

# Generic STOMP tranceiver

class Transceiver
    attr_reader :thread
    
    def initialize()
        begin
            @thread = Thread.new {
                begin
                    run()
                rescue Exception => e
                    puts "----THREAD EXCEPTION----"
                    puts e.backtrace.join("\n\t")
                end
            }
        rescue Exception => e
            puts("Cannot spawn worker thread, #{e}")
            puts("backtrace:\n  " << e.backtrace.join("\n\t"))
            exit(-1)
        end
    end
    
    def run
        raise "Must override Tranceiver.run() method!!!"
    end
    
    def stop()
        @thread.stop
    end
            
end
    
        