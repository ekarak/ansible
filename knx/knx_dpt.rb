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

require 'bindata'

module Ansible
    
    module KNX
        
        # a base class for DPT data structures.
        # derives from BinData::Record,
        # implements some common stuff 
        class DPTStruct < BinData::Record
            endian :big

            # get a DPT parameter, trying to locate it in the following order:
            #   1) in the DPTStruct field definition 
            #   2) in the DPT subtype definition
            #   3) in the DPT basetype definition
            def getparam(param, field, subtype=nil, basetype=nil)
                return (field.get_parameter(param) or 
                        (subtype and subtype[param]) or 
                        (basetype and basetype[param]))
            end
                
            # return a human-readable representation of a DPT frame
            def explain(basetype=nil, subtype=nil)
                fielddata = []
                field_names.each { |fieldname|
                    # skip padding fields
                    next if /pad/.match(fieldname)
                    field = send(fieldname)
                    fval = field.value
                    # get value encoding hashmap, if any
                    vhash = getparam(:enc, field, subtype, basetype)
                    # get value units
                    units = getparam(:unit, field, subtype, basetype) 
                    # get and apply field's scalar range, if any (only in DPT5 afaik)
                    if (sr = field.get_parameter(:scalar_range)) then
                        range = getparam(:range, field, subtype, basetype)
                        fval = to_scalar(field.value, range, sr)
                    end
                    # add field value, according to encoding hashtable
                    fielddata << "#{(vhash.is_a?Hash) ? vhash[fval] : fval} #{units}"
                } 
                return fielddata.join(', ')
            end
            
            # make sure all frame fields are valid (within min,max range) 
            def validate_ranges(basetype=nil, subtype=nil)
                # range checking is global: applies to all subtypes
                field_names.each { |fieldname|
                    # skip padding fields
                    next if /pad/.match(fieldname)
                    field = send(fieldname)
                    range = getparam(:range, field, subtype, basetype)
                    if range then
                        unless range === field.value
                            raise "#{self.class}: field #{fieldname} value (#{field.value}) out of range #{range}"
                        end
                    end
                }
            end
            
            # convert value to its scalar representation
            # e.g. in DPT5.001, 0x7F => 50%, 0xFF => 100%
            def to_scalar(val, data_range, scalar_range=nil)
                if scalar_range then
                    a = (scalar_range.max - scalar_range.min).to_f / (data_range.max - data_range.min)
                    b = (scalar_range.min - data_range.min)
                    return (a*val + b).round
                else
                    return val
                end
            end

            def from_scalar(val, data_range, scalar_range=nil)
                if scalar_range then
                    a = (scalar_range.max - scalar_range.min).to_f / (data_range.max - data_range.min)
                    b = (scalar_range.min - data_range.min)
                    #puts "a=#{a} b=#{b}"
                    return ((val - b) / a).round
                else
                    return val
                end
            end            

            
        end
        
        #
        # load all known DPT modules (incl. canonical value modules)
        Dir["knx/dpt/*.rb"].each { |f| load f }

    end
    
end
