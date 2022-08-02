#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Warnings;

plan tests => 3 + 1;


use Twitter::ID;

my $tid;


$tid = Twitter::ID->new(896523232098078720);
is $tid->epoch(), 1502582769.785, 'first epoch';

$tid = Twitter::ID->new(1445078208190291973);
is $tid->epoch(), 1633368467.744, 'second epoch';

$tid = Twitter::ID->new(78663);
is $tid->epoch(), undef, 'third epoch, pre-snowflake';


done_testing;
