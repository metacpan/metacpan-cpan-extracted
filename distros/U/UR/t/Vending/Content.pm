package Vending::Content;
use strict;
use warnings;
use Vending;

class Vending::Content {
    table_name => 'CONTENT',
    is_abstract => 1,
    subclassify_by => 'subtype_name',
    id_by => [
        content_id => {  },
    ],
    has => [
        machine             => { is => 'Vending::Machine', id_by => 'machine_id', constraint_name => 'CONTENT_MACHINE_ID_MACHINE_MACHINE_ID_FK' },
        machine_id          => { value => '1', is_constant => 1, is_classwide => 1, column_name => '' },
        machine_location_id => { is => 'integer' },
        subtype_name        => { is => 'varchar', is_optional => 1 },
        machine_location           => { is => 'Vending::MachineLocation', id_by => 'machine_location_id', constraint_name => 'CONTENT_MACHINE_LOCATION_ID_MACHINE_LOCATION_MACHINE_LOCATION_ID_FK' },
        location_name       => { via => 'machine_location', to => 'name' },
    ],
    schema_name => 'Machine',
    data_source => 'Vending::DataSource::Machine',
};

# Called when you try to create a generic Vending::Content
sub subtype_name_resolver {
    my $class = shift;

    my %params;
    if (ref($_[0])) {
        %params = %{$_[0]};  # Called with obj as arg
    } else {
        %params = @_;        # called with hash as arglist
    }
    return $params{'subtype_name'};
}
    

# Turn this thing into a Vending::ReturnedItem to give back to the user
# as a side effect, $self is deleted
sub dispense {
    my $self = shift;

    my @items_to_dispense;
    if (ref($self)) {
        # object method...
        @items_to_dispense = ($self);
    } else {
        # Class method
        @items_to_dispense = @_;
    }
    return Vending::ReturnedItem->create_from_vend_items(@items_to_dispense);
}

1;
