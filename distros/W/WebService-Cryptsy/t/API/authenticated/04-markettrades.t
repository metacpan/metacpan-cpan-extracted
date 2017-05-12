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

my $data = $cryp->markettrades( 68 );

if ( $data ) {
    cmp_deeply(
        $data,
        array_each(
            {
                'quantity' => re('^[-+.\d]+$'),
                'tradeid' => re('^\d+$'),
                'initiate_ordertype' => re('.'),
                'total' => re('^[-+.\d]+$'),
                'tradeprice' => re('^[-+.\d]+$'),
                'datetime' => re('.'),
            },
        ),
        '->markettrades returned an expected arrayref'
    );
}
else {
    diag "Got an error getting an API request: $cryp";
    ok( length $cryp->error );
}