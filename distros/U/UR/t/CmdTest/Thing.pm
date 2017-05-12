package CmdTest::Thing;
use UR;
class CmdTest::Thing {
    is => 'UR::Object',
    has          => { param_a => { is => 'String', }, },
    has_optional => { param_a => { is => 'Number', }, },
    doc => 'This is a thing',
};
1;
