package Vending::Command::Service::RemoveSlot;
use strict;
use warnings;

use Vending;
class Vending::Command::Service::RemoveSlot {
    is => ['Vending::Command::Outputter', 'Vending::Command::Service'],
    doc => 'Uninstall the named slot and remove all the items',
    has => [
        name => { is => 'String', doc => 'Name of the slot to empty out' },
    ], 
};


sub _get_items_to_output {
    my $self = shift;
    my $machine = $self->machine();

    my @items = $machine->empty_machine_location_by_name($self->name);

    my $loc = $machine->machine_locations(name => $self->name);
    $loc->delete;

    return @items;
}
1;

