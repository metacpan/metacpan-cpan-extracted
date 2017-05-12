package Vending::Command::Service::EmptyBank;
use strict;
use warnings;

use Vending;
class Vending::Command::Service::EmptyBank {
    is => ['Vending::Command::Outputter', 'Vending::Command::Service'],
    doc => 'Get all the money out of the bank',
};


sub _get_items_to_output {
    my $self = shift;
    my $machine = $self->machine();
    my @coins = $machine->empty_bank();
    return @coins;
}
1;

