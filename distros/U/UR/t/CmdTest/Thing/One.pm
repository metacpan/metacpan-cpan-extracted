package CmdTest::Thing::One;
use UR;
class CmdTest::Thing::One {
    is => 'CmdTest::Thing',
    has          => { param_1a => { is => 'String', }, },
    has_optional => { param_1b => { is => 'Number', }, },
};
1;
