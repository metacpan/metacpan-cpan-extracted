package Monkey::PatchD;

use strict;
use warnings;

use ex::monkeypatched -norequire => 'Monkey::D' => (
    monkey_d => sub { 'in Monkey::PatchD monkey_d' },
);

1;
