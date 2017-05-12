package Vending::Command::Service::Add;
use strict;
use warnings;

use Vending;
class Vending::Command::Service::Add {
    is => 'Vending::Command::Service',
    doc => 'Add items to the vending machine',
    is_abstract => 1,
};

1;

