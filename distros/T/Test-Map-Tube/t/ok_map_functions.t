#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use lib 't/';
use Sample;
use Test::Map::Tube;

ok_map_functions(Sample->new);
