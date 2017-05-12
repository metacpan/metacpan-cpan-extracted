package Vending::Product;

use strict;
use warnings;

use Vending;
class Vending::Product {
    is => [ 'Vending::ContentType' ],
    table_name => 'PRODUCT',
    id_sequence_generator_name => 'URMETA_content_type_TYPE_ID_seq',
    id_by => [
        product_id => { is => 'integer' },
    ],
    has => [
        manufacturer      => { is => 'varchar' },
        cost_cents        => { is => 'integer' },
        price             => { calculate_from => 'cost_cents',
                         calculate => q(sprintf("\$%.2f", $cost_cents/100)), 
                         doc => 'display price in dollars' },
        item_type_product => { is => 'Vending::ContentType', id_by => 'product_id', constraint_name => 'PRODUCT_PRODUCT_ID_CONTENT_TYPE_TYPE_ID_FK' },
    ],
    schema_name => 'Machine',
    data_source => 'Vending::DataSource::Machine',
    doc => 'kinds of things the machine sells',
};

1;
