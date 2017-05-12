package Vending::Merchandise;

use strict;
use warnings;

use Vending;
class Vending::Merchandise {
    is => [ 'Vending::Content' ],
    table_name => 'merchandise',
    id_sequence_generator_name => 'URMETA_coin_coin_ID_seq',
    id_by => [
        merchandise_id => { is => 'integer' },
    ],
    has => [
        product      => { is => 'Vending::Product', id_by => 'product_id', constraint_name => 'inventory_product_ID_product_product_ID_FK' },
        insert_date  => { is => 'datetime' },
        product_id   => { is => 'integer', implied_by => 'product' },
        name         => { via => 'product' },
        cost_cents   => { via => 'product' },
        price        => { via => 'product' },
        manufacturer => { via => 'product' },
    ],
    schema_name => 'Machine',
    data_source => 'Vending::DataSource::Machine',
    doc => 'instances of things the machine will sell and dispense',
};

sub subtype_name_resolver {
    return __PACKAGE__;
}

1;
