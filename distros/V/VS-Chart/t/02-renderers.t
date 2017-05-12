#!perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

use VS::Chart;

my $chart = VS::Chart->new();

throws_ok {
   $chart->render(type => '_');
} qr/Unsupported chart type: _/;