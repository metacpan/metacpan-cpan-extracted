#!perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN { use_ok("VS::Chart"); }

use VS::Chart;

my $chart = VS::Chart->new();

is($chart->get("_defaults"), 1);

$chart->set("foo" => 2);
is($chart->get("foo") => 2);

# Add data so we get a dataset
$chart->add(10);
ok(!defined $chart->_dataset(0)->get("foo"));
$chart->_dataset(0)->set("foo" => 1);
is($chart->_dataset(0)->get("foo"), 1);
$chart->set("0: foo" => 2);
is($chart->_dataset(0)->get("foo"), 2);

