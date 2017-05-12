package Vending::ContentType;

use strict;
use warnings;

use Vending;
class Vending::ContentType {
    table_name => 'content_type',
    id_by => [
        type_id => { is => 'integer' },
    ],
    has => [
        name => { is => 'varchar' },

        machine_id => { value => '1', is_constant => 1, is_classwide => 1, column_name => '' },
        machine    => { is => 'Vending::Machine', id_by => 'machine_id' },

        count       => { calculate_from => ['type_id'],
                         calculate => \&count_items_by_type,
                         doc => 'How many items of this type are there' },

    ],
    id_sequence_generator_name => 'URMETA_content_type_TYPE_ID_seq',
    doc => 'abstract base class for things the machine knows about',
    schema_name => 'Machine',
    data_source => 'Vending::DataSource::Machine',
};

sub count_items_by_type {
    my $type_id = shift;

    my $item = Vending::CoinType->get($type_id) || Vending::Product->get($type_id);

    my @objects;
    if ($item->isa('Vending::CoinType')) {
        @objects = Vending::Coin->get(type_id => $type_id);
    }  else {
        @objects = Vending::Merchandise->get(product_id => $type_id);
    }
    return scalar(@objects);
}

1;

