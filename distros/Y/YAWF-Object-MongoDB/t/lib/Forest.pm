package t::lib::HeavyGroups;

use strict;
use warnings;

use YAWF::Object::MongoDB (
    collection => 'Y_O_M_Test_HeavyGroups',
    keys       => [ {},
                    { one => 1 },
                    { two => 1 },
                    { three => 1 },
                    { four => 1 },
                    { five => 1 },
    ]
);

our @ISA = ('YAWF::Object::MongoDB');

1;
