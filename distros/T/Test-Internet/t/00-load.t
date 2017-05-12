#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Test::Internet') || print "Bail out!\n"; }
diag( "Testing Test::Internet $Test::Internet::VERSION, Perl $], $^X" );
