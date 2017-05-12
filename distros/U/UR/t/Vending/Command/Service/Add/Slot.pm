package Vending::Command::Service::Add::Slot;
use strict;
use warnings;

use Vending;
class Vending::Command::Service::Add::Slot {
    is => 'Vending::Command::Service::Add',
    doc => 'Install a new vending slot into the machine',
    has => [
        name  => { is => 'String', doc => 'Button name for the slot' },
        label => { is => 'String', doc => 'Display label for this slot' },
        cost  => { is => 'Integer', doc => 'Price for this slot, in cents' },
    ],
};

sub execute {
    my $self = shift;

    my $machine = $self->machine;
    my $slot = $machine->add_machine_location(name => $self->name,
                                              label => $self->label,
                                              cost_cents => $self->cost,
                                              is_buyable => 1);

    return 1;
}
1;

