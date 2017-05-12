package Vending::Command::Nickel;
use strict;
use warnings;

class Vending::Command::Nickel {
    is => 'Vending::Command::InsertMoney',
    has => [
        name => { is_constant => 1, value => 'nickel' },
    ],
    doc => 'Insert a Nickel into the machine',
};

1;

