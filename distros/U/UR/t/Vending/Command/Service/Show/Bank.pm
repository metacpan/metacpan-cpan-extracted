package Vending::Command::Service::Show::Bank;

use strict;
use warnings;

use Vending;

class Vending::Command::Service::Show::Bank {
    is => 'Vending::Command::Service::Show::Money',
    doc => "Show how much money is in the machine's bank",
    has => [
        location_name => { value => 'bank' },
    ],
};

1;

