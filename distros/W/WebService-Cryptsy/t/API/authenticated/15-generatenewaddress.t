#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Deep;

plan tests => 3;

use WebService::Cryptsy;

open my $fh, '<', 't/API/authenticated/KEYS'
    or BAIL_OUT("Can't get the keys: $!");
chomp( my @keys = <$fh> );

my $cryp = WebService::Cryptsy->new(
    public_key  => $keys[0],
    private_key => $keys[1],
    timeout => 10,
);

my $data = $cryp->generatenewaddress(
    3,
    'BTC',
);

if ( $data ) {
    cmp_deeply(
        $data,
        {
            'address' => re('.'),
        },
        '->generatenewaddress returned an expected hashref'
    );
}
else {
    diag "Got an error getting an API request: $cryp";
    ok( length $cryp->error );
}

$data = $cryp->generatenewaddress(
    undef,
    'BTC',
);

if ( $data ) {
    cmp_deeply(
        $data,
        {
            'address' => re('.'),
        },
        '->generatenewaddress returned an expected hashref '
        . 'with currency code'
    );
}
else {
    diag "Got an error getting an API request: $cryp";
    ok( length $cryp->error );
}

$data = $cryp->generatenewaddress(
    3,
);

if ( $data ) {
    cmp_deeply(
        $data,
        {
            'address' => re('.'),
        },
        '->generatenewaddress returned an expected hashref '
        . 'with currency ID'
    );
}
else {
    diag "Got an error getting an API request: $cryp";
    ok( length $cryp->error );
}