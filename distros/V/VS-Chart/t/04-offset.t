#!perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use VS::Chart;

my $chart = VS::Chart->new();

throws_ok {
    $chart->_offset(10);
} qr/Value '10' is outside value range/;

$chart->set(min => 0);
$chart->set(max => 10);

is($chart->_offset(5), 0.5);
is($chart->_offset(2), 0.2);

$chart->set(min => -10);
is($chart->_offset(5), 0.75);
is($chart->_offset(-5), 0.25);

$chart->add(15);
$chart->add(0);
is($chart->_offset(7.5), 0.5);

$chart = VS::Chart->new();
$chart->set(min => 0);
$chart->set(max => 10);
is_deeply([$chart->_offsets(1, 4, 7)], [0.1, 0.4, 0.7]);