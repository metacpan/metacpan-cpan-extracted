#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

plan tests => 1;

use WebService::Cryptsy;

my $cryp = WebService::Cryptsy->new( timeout => 10 );

my $data = $cryp->singleorderdata( 68 );
if ( $data ) {
    cmp_deeply(
        $data,
        hash_each(
            {
                'primaryname' => 'CasinoCoin',
                'marketid' => '68',
                'secondarycode' => 'BTC',
                'primarycode' => 'CSC',
                'label' => re('.'),
                'secondaryname' => 'BitCoin',
                'buyorders' => any(
                    array_each(
                        {
                            'quantity' => re('^[-+.\d]+$'),
                            'price' => re('^[-+.\d]+$'),
                            'total' => re('^[-+.\d]+$'),
                        },
                    ),
                    undef,
                ),
                'sellorders' => any(
                    array_each(
                        {
                            'quantity' => re('^[-+.\d]+$'),
                            'price' => re('^[-+.\d]+$'),
                            'total' => re('^[-+.\d]+$'),
                        },
                    ),
                    undef,
                ),
            }
        ),
        '->singleorderdata returns an expected hashref',
    );
}
else {
    diag "Got an error getting an API request: $cryp";
    ok( length $cryp->error );
}