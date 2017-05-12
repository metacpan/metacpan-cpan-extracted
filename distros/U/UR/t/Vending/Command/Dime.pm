package Vending::Command::Dime;
use strict;
use warnings;

class Vending::Command::Dime {
    is => 'Vending::Command::InsertMoney',
    has => [
        name => { is_constant => 1, value => 'dime' },
    ],
    doc => 'Insert a dime into the machine',
};

1;

