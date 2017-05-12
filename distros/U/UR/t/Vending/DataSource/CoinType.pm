package Vending::DataSource::CoinType;
use strict;
use warnings;
use Vending;

my $path = Vending->get_base_directory_name() . '/DataSource/coin_types.tsv';

class Vending::DataSource::CoinType {
    is => ['UR::DataSource::File','UR::Singleton'],
    has_constant => [
        server => { value => $path },
        delimiter => { value => '\s+' },
        column_order => { value => ['name','value_cents'] },
        sort_order => { value => ['name'] },
    ],
};

1;

