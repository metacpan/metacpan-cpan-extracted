#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Test::Strict') || print "Bail out!\n"; }

diag( "Testing Test::Strict $Test::Strict::VERSION, Perl $], $^X" );
