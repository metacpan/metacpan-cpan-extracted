#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

use WebService::Cryptsy;

my $cryp = WebService::Cryptsy->new( timeout => 10 );

isa_ok($cryp, 'WebService::Cryptsy');
can_ok($cryp, qw/
    marketdata
    marketdatav2
    singlemarketdata
    orderdata
    singleorderdata
/);

