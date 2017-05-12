package CmdTest::Thing::Two;
use UR;
class CmdTest::Thing::Two {
    is => 'CmdTest::Thing',
    has          => { param_2a => { is => 'String', }, },
    has_optional => { param_2b => { is => 'Number', }, },
};
1;
