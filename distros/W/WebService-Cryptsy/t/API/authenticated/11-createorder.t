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

#####
##### Since we can't really create orders with this account,
##### let's do some extra error checking.
#####
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
