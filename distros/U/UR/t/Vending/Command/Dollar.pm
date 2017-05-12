package Vending::Command::Dollar;
use strict;
use warnings;

class Vending::Command::Dollar {
    is => 'Vending::Command::InsertMoney',
    has => [
        name => { is_constant => 1, value => 'dollar' },
    ],
    doc => 'Insert a dollar into the machine',
};

1;

