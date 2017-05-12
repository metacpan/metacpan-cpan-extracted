package Vending::Command::Service::ConfigureSlot;
use strict;
use warnings;
use Vending;

class Vending::Command::Service::ConfigureSlot {
    is => 'Vending::Command::Service',
    has => [
        name => { is => 'String', doc => 'Slot name' },
        label => { is => 'String', doc => 'New label for the slot', is_optional => 1 },
        cost_cents => { is => 'String', doc => 'New price for this slot', is_optional => 1 },
    ],
};

sub execute {
    my $self = shift;

    my $machine = $self->machine();
    my $loc = $machine->machine_locations(name => $self->name);
    unless ($loc) {
        $self->error_message("Not a valid slot name");
        return;
    }

    if (defined $self->label) {
        $loc->label($self->label);
    }
    if (defined $self->cost_cents) {
        $loc->cost_cents($self->cost_cents);
    }
    return 1;
}
1;

