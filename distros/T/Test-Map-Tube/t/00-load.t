#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Test::Map::Tube') || print "Bail out!\n"; }

diag( "Testing Test::Map::Tube $Test::Map::Tube::VERSION, Perl $], $^X" );
