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

require 'knx_transceiver'
require 'knx_protocol'
require 'knx_tools'

module Ansible
    
    module KNX
        
    # definition: a KNXValue is the device-dependant datapoint, having a
    # well defined data type (EIS type): EIS1 (boolean), EIS5 (float) 
    # linked to zero or more group addresses,
    
    class KNXValue
        include AnsibleValue
        
        #
        # ------ CLASS VARIABLES & METHODS
        #
        @@ids = 0
        def KNXValue.id_generator
            @@ids = @@ids + 1
            return @@ids
        end
        
        #
        # ----- INSTANCE VARIABLES & METHODS
        #
                
        # equality checking
        def == (other)
            return (@id == other.id)
        end
        
        attr_reader :groups, :dpt_type, :id
        attr_accessor :description

        # initialize KNXValue
        def initialize(transceiver, groups=[], flags=nil)
            # the transceiver responsible for all things KNX
            @transceiver = transceiver

            # array of group addresses associated with this datapoint
            # only the first address is used in a  write operation (TODO: CHECKME)
            @groups = case groups
                when String then Array[str2addr(groups)]
                when Array then groups
            end
            
            # set flag: knxvalue.flags[:r] = true
            # test flag: knxvalue.flags[:r]  (evaluates to true, meaning the read flag is set)
            @flags = flags or {}
            # c => Communication
            # r => Read
            # w => Write
            # t => Transmit
            # u => Update
            # i => read on Init
            
            # physical address: set only for remote nodes we are monitoring
            # when left to nil, it/ means a datapoint on this KNXTransceiver 
            @physaddr = nil
            
            # time of last update
            @last_update = nil
            
            # id of datapoint
            # initialized by class method KNXValue.id_generator
            @id = KNXValue.id_generator()
        end
        
        # get a value from eibd
        def get()
            
        end
        
        # set (write) a value to eibd
        def set(new_val)
            #write value to primary group address
            dest = nil
            if @groups.length > 0 then 
                dest = @groups[0]
            else
                raise "#{self}: primary group address not set!!!"
            end
            apdu = create_apdu()
            puts "#{self}: Writing value to #{addr2str(dest)}"
            #
            @transceiver.send_apdu_raw(dest, apdu)
        end
        
        def group_primary=(grpaddr)
            @groups.unshift(grpaddr)
        end
        
        def groups=(other)
            raise "KNXValue.groups= requires an array of at least one group addresses" unless (other.is_a?Array) and (other.length > 0)
            @groups.replace(other)
        end
        
        def create_apdu
            raise "must override create_apdu!!!"
        end
        
    end #class KNXValue
 
    #
    # now we can load all known KNXValue_DPT** classes
    Dir["knx/dpt/*.rb"].each { |f| load f }
    
    end #module KNX
    
end #module Ansible
