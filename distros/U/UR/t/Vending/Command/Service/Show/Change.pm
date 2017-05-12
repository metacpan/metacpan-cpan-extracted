package Vending::Command::Service::Show::Change;

use strict;
use warnings;

use Vending;

class Vending::Command::Service::Show::Change {
    is => 'Vending::Command::Service::Show::Money',
    doc => "Show how much money is in the machine's change dispenser",
    has => [
        location_name => { value => 'change' },
    ],
};

1;

