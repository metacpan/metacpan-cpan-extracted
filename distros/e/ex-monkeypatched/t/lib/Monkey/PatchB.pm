package Monkey::PatchB;

use strict;
use warnings;

use ex::monkeypatched 'Monkey::B' => (
    monkey_b => sub { 'in Monkey::PatchB monkey_b' },
    already_exists => sub { 'in Monkey::PatchB already_exists' },
);

1;
