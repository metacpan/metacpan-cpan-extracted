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

diag "\n###############################################################\n"
    . "If you see a bunch of 'Use of uninitialized value "
    . "in string eq at .... Test/Deep/ArrayEach',"
    . " it's fine; don't worry about it"
    . "\n#############################################################\n";

my $data = $cryp->getinfo;

if ( $data ) {
    cmp_deeply(
        $data,
        subhashof({
            'openordercount' => re('^\d+$'),
            'servertimestamp' => re('^\d+$'),
            'servertimezone' => re('.'),
            'balances_available' => hash_each(
                re('^[-+.\d]+$'),
            ),
            'serverdatetime' => re('.'),
            'balances_hold' => hash_each(
                re('^[-+.\d]+$'),
            ),
            'balances_available_btc' => re('.'),
        }),
        '->getinfo returned an expected arrayref'
    );
}
else {
    diag "Got an error getting an API request: $cryp";
    ok( length $cryp->error );
}