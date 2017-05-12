#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::Tarantool' ) || print "Bail out!\n";
}

diag( "Testing Test::Tarantool $Test::Tarantool::VERSION, Perl $], $^X" );
