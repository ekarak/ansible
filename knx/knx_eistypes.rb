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

    module KNX
    
        # the skeleton class for the datatypes in use by the KNX standard
        class EISType
        
            # singleton hash holding all known EISType instances
            # key => primary_type (integer 1 to 255)
            # value => hash of secondary types (secondary_type => instance)
            #       -- NOTE: the contained secondary types hash can be set
            #       to report a default instance that holds a generic EISType.
            #       Thus we define datatypes with great granularity.
            @@alltypes = {}
            
            # method for getting all known EIS types as a flat array
            def EISType.all
                return @@alltypes.values.collect{ |st| st.values + st.default}.flatten.compact
            end
            
            # initializes a new datatype
            def initialize(primary_type, secondary_type)
                puts "Initializing new EISType pri=#{primary_type} sec=#{secondary_type}"
                @primary_type , @secondary_type = primary_type , secondary_type  
                @@alltypes[primary_type] = {} unless @@alltypes[primary_type].is_a? Hash
                # store ourselves in the big hash of types
                if secondary_type.nil? then
                    puts "==> Redeclaring default EISType for primary=#{primary_type}" if @@alltypes[primary_type] 
                    @@alltypes[primary_type].default = self
                else
                    @@alltypes[primary_type][secondary_type] = self
                end
            end
            
            # return a human-readable description for this EISType
            def to_s
                return 'EIS' + @primary_type.to_s + (@secondary_type.nil? ? "" : ".#{@secondary_type}") 
            end
            
            # takes a KNX value and abstracts its data
            # usage: eis1.abstractor {|value| value.to_s }
            
            def abstractor=(&block)
                # in its most basic form, abstract_value just returns the value
                return(value.get()
            end
            
        end # class
        
    end #module KNX
    
end #module Ansible
