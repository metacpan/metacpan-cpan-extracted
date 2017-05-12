package Vending::Command::Service::Add::Change;
use strict;
use warnings;

use Vending;
class Vending::Command::Service::Add::Change {
    is => 'Vending::Command::Service::Add',
    doc => 'Add change to the vending machine',
    has => [
        name => { is => 'String', doc => 'Name of the coin' },
        count => { is => 'Integer', doc => 'How many you are adding' },
    ],
};

sub execute {
    my $self = shift;

    my $machine = $self->machine();

    my $coin_kind = Vending::CoinType->get(name => $self->name);
    unless ($coin_kind) {
        $self->error_message($self->name." is not a valid coin name");
        return;
    }

    my $change_disp = $machine->change_dispenser;
    unless ($change_disp) {
        die "Couldn't retrieve money location for 'change'";
    }

    my $count = $self->count;
    while($count--) {
        my $coin = $change_disp->add_item(subtype_name => 'Vending::Coin', type_id => $coin_kind->type_id, machine_id => $self);
        1;
    }

    return 1;
}
1;

