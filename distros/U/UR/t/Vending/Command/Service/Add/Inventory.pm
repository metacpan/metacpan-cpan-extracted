package Vending::Command::Service::Add::Inventory;
use strict;
use warnings;

use Vending;
class Vending::Command::Service::Add::Inventory {
    is => 'Vending::Command::Service::Add',
    doc => 'Add a sellable item to the vending machine',
    has => [
        slot => { is => 'String', doc => 'Slot name you are putting the product into' },
        name => { is => 'String', doc => 'Name of the item, default is the label on the slot', is_optional => 1 },
        count => { is => 'Integer', doc => 'How many you are adding, default is 1', default_value => 1 },
    ],
};

sub help_detail {
    q(Add inventory to the machine in the given slot.  You are allowed to put
items into a slot that do not necessarily match the slot's label name.

Example:
    vend service add inventory --slot a --name Cookie --count 4
);
}

sub execute {
    my $self = shift;

    my $machine = $self->machine;

    my $loc = $machine->machine_locations(name => $self->slot);
    unless ($loc) {
        die "There is no slot with that name";
    }

    unless (defined $self->name) {
        print "Adding ",$loc->label,"(s)\n";
        $self->name($loc->label);
    }

    my $item_kind = $machine->products(name => $self->name);
    unless ($item_kind) {
        print "This is a new item.  What is the manufacturer:\n";
        my $manufacturer = <STDIN>;
        print "What is the cost (dollars)\n";
        my $price = <STDIN>;
        $price = int($price * 100);  # Convert to cents
        $item_kind = $machine->add_product(name => $self->name, manufacturer => $manufacturer, cost_cents => $price);
    }

    my $count = $self->count;
    while($count--) {
        my $item = $loc->add_item(subtype_name => 'Vending::Merchandise', product_id => $item_kind->id, insert_date => time(), machine_id => $self);
    }

    return 1;
}
1;

