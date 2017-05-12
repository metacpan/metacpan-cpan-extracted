#!perl

use strict;
use warnings;

use Test::More tests => 21;

use VS::Chart;

my $chart = VS::Chart->new();

is($chart->_min, 0);
is($chart->_max, 0);
is($chart->_span, 0);

$chart->add(1);
is($chart->_min, 1);
is($chart->_max, 1);
is($chart->_span, 0);

$chart->add(10);
is($chart->_min, 1);
is($chart->_max, 10);
is($chart->_span, 9);

$chart->add(-10);
is($chart->_min, -10);
is($chart->_max, 10);
is($chart->_span, 20);

$chart->add(undef, 20);
is($chart->_min, -10);
is($chart->_max, 20);
is($chart->_span, 30);

$chart->set(min => 0);
is($chart->_min, -10);

$chart->set(max => 15);
is($chart->_max, 20);

$chart = VS::Chart->new();
is($chart->_min, 0);
is($chart->_max, 0);
$chart->set(min => -10);
$chart->set(max => 10);
is($chart->_min, -10);
is($chart->_max, 10);
