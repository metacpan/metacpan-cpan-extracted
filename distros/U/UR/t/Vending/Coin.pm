package Vending::Coin;

use strict;
use warnings;

use Vending;
class Vending::Coin {
    table_name => 'COIN',
    is => 'Vending::Content',
    id_by => [
        coin_id => { is => 'integer' },
    ],
    has => [
        name         => { via => 'item_type', to => 'name' },
        value_cents  => { via => 'coin_type', to => 'value_cents' },
        coin_type    => { is => 'Vending::CoinType', id_by => 'name' },
        item_type      => { is => 'Vending::ContentType', id_by => 'type_id', constraint_name => 'COIN_TYPE_ID_CONTENT_TYPE_TYPE_ID_FK' },
    ],
    schema_name => 'Machine',
    data_source => 'Vending::DataSource::Machine',
};

sub subtype_name_resolver {
    return __PACKAGE__;
}


1;
