#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

plan tests => 3 + 3 + 1 + 2 + 6 + 1;


use Twitter::ID;

my $tid;


$tid = Twitter::ID->new(896523232098078720);
is $tid->timestamp(), 1502582769785, 'first timestamp';
is $tid->worker(), 373, 'first worker';
is $tid->sequence, 0, 'first sequence';

$tid = Twitter::ID->new(1445078208190291973);
is $tid->timestamp(), 1633368467744, 'second timestamp';
is $tid->worker(), 370, 'second worker';
is $tid->sequence, 5, 'second sequence';

$tid = Twitter::ID->new({ timestamp => 1402076979493, worker => 129, sequence => 0 });
is $$tid, 474971393852182528, 'constructor with values';

lives_ok { $tid = Twitter::ID->new(0); } 'constructor zero';
is $$tid, 0, 'fourth snowflake';

lives_ok { $tid = Twitter::ID->new({}); } 'constructor without values';
is $$tid, 0, 'fifth snowflake zero';
lives_ok { $tid->timestamp(1380269002737) } 'fifth timestamp';
lives_ok { $tid->worker(35) } 'fifth worker';
lives_ok { $tid->sequence(1) } 'fifth sequence';
is $$tid, 383502109712199681, 'fifth snowflake';


done_testing;
