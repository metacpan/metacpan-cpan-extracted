#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Deep;

plan tests => 1;

use WebService::Cryptsy;
use Data::Dumper;

open my $fh, '<', 't/API/authenticated/KEYS'
    or BAIL_OUT("Can't get the keys: $!");
chomp( my @keys = <$fh> );

my $cryp = WebService::Cryptsy->new(
    public_key  => $keys[0],
    private_key => $keys[1],
    timeout => 10,
);

my $data = $cryp->getmarkets;

if ( $data ) {
    cmp_deeply(
        $data,
        array_each(
            {
                'current_volume' => re('^[-+.\d]+$'),
                'current_volume_btc' => re('^[-+.\d]+$'),
                'current_volume_usd' => re('^[-+.\d]+$'),
                'marketid' => re('^\d+$'),
                'created' => re('.'),
                'high_trade' => re('^[-+.\d]+$'),
                'primary_currency_name' => re('.'),
                'secondary_currency_name' => re('.'),
                'last_trade' => re('^[-+.\d]+$'),
                'primary_currency_code' => re('.'),
                'label' => re('.'),
                'secondary_currency_code' => re('.'),
                'low_trade' => re('^[-+.\d]+$'),
            },
        ),
        '->getmarkets returned an expected arrayref'
    );
}
else {
    diag "Got an error getting an API request: $cryp";
    ok( length $cryp->error );
}