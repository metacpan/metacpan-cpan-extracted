#!/usr/bin/env perl
use strict;
use Test::More tests => 18;
use File::Basename;
my $dir=dirname $0;

chdir $dir;

use Util::Properties::Combine;

#$Util::Properties::VERBOSE=2;


my $p1=Util::Properties::Combine->new(file=>"data/p1.properties");
$p1->file_ismirrored(0);
my $p2=Util::Properties::Combine->new(file=>"data/p2.properties");
$p2->file_ismirrored(0);

is($p1->prop_get('prout.alpha'),1, "p1 orig alpha val");
is($p1->prop_get('prout.beta'),10, "p1 orig beta val");
is($p1->prop_get('prout.gamma'),100, "p1 orig gamma val");
is($p2->prop_get('prout.alpha'),2, "p2 orig alpha val");
is($p2->prop_get('prout.gamma'),300, "p2 orig gamma val");
is($p2->prop_get('prout.delta'),1000, "p2 orig delta val");

$p1 += $p2;
is($p1->prop_get('prout.alpha'),3, "p1 += alpha val");
is($p1->prop_get('prout.beta'),10, "p1 += beta val");
is($p1->prop_get('prout.gamma'),400, "p1 += gamma val");
is($p1->prop_get('prout.delta'),1000, "p1 += delta val");

$p1 -= $p2;
$p1 -= $p2;

is($p1->prop_get('prout.alpha'),-1, "p1 -= alpha val");
is($p1->prop_get('prout.beta'),10, "p1 -= beta val");
is($p1->prop_get('prout.gamma'),-200, "p1 -= gamma val");
is($p1->prop_get('prout.delta'),-1000, "p1 -= delta val");


$p1=Util::Properties::Combine->new(file=>"data/p1.properties");
$p1->file_ismirrored(0);

my $l1=Util::Properties::Combine->new(file=>"data/l1.properties");
ok($l1>=$p1, 'l1 >= p1');
$p1+=$p1;
ok($l1>=$p1, 'p1+=p1; l1 >= p1');
$p1+=$p1;
ok(! ($l1>=$p1), 'p1+=p1; NOT l1 >= p1');
ok(! ($l1<=$p1), 'NOT l1 <= p1');

