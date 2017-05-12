package Monkey::PatchA;

use strict;
use warnings;

use ex::monkeypatched 'Monkey::A' => (
    monkey_a1 => sub { 'in Monkey::PatchA monkey_a1' },
    monkey_a2 => sub { 'in Monkey::PatchA monkey_a2' },
);

1;
