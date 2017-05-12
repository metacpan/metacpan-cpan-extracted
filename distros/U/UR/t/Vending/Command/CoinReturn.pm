package Vending::Command::CoinReturn;
use strict;
use warnings;

class Vending::Command::CoinReturn {
    is => 'Vending::Command::Outputter',
    doc => 'Return all inserted coins back to the customer',
};

sub _get_items_to_output {
    my $self = shift;

    my $machine = $self->machine();
    my @items = $machine->coin_return();
    return @items;
}
1;

