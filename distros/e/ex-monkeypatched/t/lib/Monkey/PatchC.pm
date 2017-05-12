package Monkey::PatchC;

use strict;
use warnings;

use ex::monkeypatched 'Monkey::C' => (
    monkey_b => sub { 'in Monkey::PatchC monkey_c' },
    heritable => sub { 'in Monkey::PatchC heritable' },
);

1;
