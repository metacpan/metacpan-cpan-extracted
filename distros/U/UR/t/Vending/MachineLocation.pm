package Vending::MachineLocation;

use strict;
use warnings;

use Vending;
class Vending::MachineLocation {
    table_name => 'MACHINE_LOCATION',
    id_by => [
        machine_location_id => { is => 'integer' },
    ],
    has => [
        name                  => { is => 'varchar' },
        label                 => { is => 'varchar', is_optional => 1 },
        is_buyable            => { is => 'integer' },
        cost_cents            => { is => 'integer', is_optional => 1 },
        items                 => { is => 'Vending::Content', reverse_as => 'machine_location', is_many => 1 },
        coins                 => { is => 'Vending::Coin', reverse_as => 'machine_location', is_many => 1 },
        count                 => { calculate => q(my @obj = $self->items; 
                                        return scalar(@obj);), 
                         doc => 'How many items are in this machine_location' },
        content_value         => { calculate => q(my @obj = $self->items; 
                                          my $val = 0;
                                          $val += $_->isa('Vending::Coin') ? $_->value_cents : $_->cost_cents foreach @obj;
                                          return $val;), 
                         doc => 'Value of all the items in this machine_location' },
        content_value_dollars => { calculate_from => 'content_value',
                         calculate => q(sprintf("\$%.2f", $content_value/100)), 
                         doc => 'Value of all the contents in dollars' },
        price                 => { calculate_from => 'cost_cents',
                         calculate => q(sprintf("\$%.2f", $cost_cents/100)), 
                         doc => 'display price in dollars' },
        machine               => { is => 'Vending::Machine', id_by => 'machine_id', constraint_name => 'MACHINE_LOCATION_MACHINE_ID_MACHINE_MACHINE_ID_FK' },
        machine_id            => { is => 'integer' },
    ],
    schema_name => 'Machine',
    data_source => 'Vending::DataSource::Machine',
    doc => 'represents a "machine_location" in the machine, such as "A", "B", "user","change"',
};


sub transfer_items_to_machine_location {
    my($self,$to_machine_location) =@_;

    my $to_machine_location_id = $to_machine_location->id;

    my @objects = $self->items();
    $_->machine_location_id($to_machine_location_id) foreach @objects;

    return scalar(@objects);
}

1;

