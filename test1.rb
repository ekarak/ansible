$:.push(Dir.getwd)
$:.push(File.join(Dir.getwd, 'knx'))
$:.push(File.join(Dir.getwd, 'zwave'))

load 'transceiver.rb'
load 'zwave_transceiver.rb'
load 'zwave_command_classes.rb'

stomp_url = 'stomp://localhost'
thrift_url = 'thrift://localhost'

ZWT = Ansible::ZWave_Transceiver.new(stomp_url, thrift_url)
ZWT.manager.SendAllValues
sleep(3)
if Dimmer = AnsibleValue[ 
    :_nodeId => 5, 
    :_commandClassId => OpenZWave::CommandClassesByName[:COMMAND_CLASS_SWITCH_MULTILEVEL],
    :_type => OpenZWave::RemoteValueType::ValueType_Byte,
    :_valueIndex => 0
    ] then
    Dimmer[0].declare_callback(:onUpdate) { | val, event|
        puts "ZWAVE EVENT  #{val}.#{event}! CURRENT VALUE==#{val.current_value} --------------------"
    }
else
    puts "valueid not found!"
end
    
Tree = AnsibleValue[ 
    :_nodeId => 2, 
    :_commandClassId => 32
    ][0]
