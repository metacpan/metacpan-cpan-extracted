#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

use WebService::Cryptsy;


open my $fh, '<', 't/API/authenticated/KEYS'
    or BAIL_OUT("Can't get the keys: $!");
chomp( my @keys = <$fh> );

my $cryp = WebService::Cryptsy->new(
    public_key  => $keys[0],
    private_key => $keys[1],
    timeout => 10,
);

$cryp->createorder(
    68,
    'Sell',
    '100',
    '199',
);

ok(
    "$cryp" =~ /Insufficient CSC in account to complete this order|Network/,
    '->createorder produces an expected error',
);

is($cryp->error, "$cryp", 'object interpolation overload returns ->error');

is($cryp->timeout, 10, '->timeout returns expected value');
$cryp->timeout(20);
is($cryp->timeout, 20, '->timeout returns expected value, '
    . 'after setting a new value');
