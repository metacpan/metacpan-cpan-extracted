#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use lib 't/';
use Sample;
use Test::Map::Tube;

my $routes =
[
   "Route 1|A1|A3|A1,A2,A3",
   "#Route 2|A1|A3|A1,A3",
];

ok_map_routes(Sample->new, $routes);
