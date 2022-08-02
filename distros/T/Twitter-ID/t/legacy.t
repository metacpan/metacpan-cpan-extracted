#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Warnings;

plan tests => 4*3 + 1;


use Twitter::ID;

my $tid;


$tid = Twitter::ID->new(20);
is $$tid, 20, 'fifth snowflake';
is $tid->timestamp(), undef, 'first timestamp';
is $tid->worker(), undef, 'first worker';
is $tid->sequence, undef, 'first sequence';

$tid = Twitter::ID->new(29700859247);
is $$tid, 29700859247, 'second snowflake';
is $tid->timestamp(), undef, 'second timestamp';
is $tid->worker(), undef, 'second worker';
is $tid->sequence, undef, 'second sequence';

$tid = Twitter::ID->new(78663);
is $$tid, 78663, 'third snowflake';
is $tid->timestamp(), undef, 'third timestamp';
is $tid->worker(), undef, 'third worker';
is $tid->sequence, undef, 'third sequence';


done_testing;
