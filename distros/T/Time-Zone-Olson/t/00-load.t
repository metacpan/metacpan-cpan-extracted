#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Time::Zone::Olson' ) || print "Bail out!\n";
}

diag( "Testing Time::Zone::Olson $Time::Zone::Olson::VERSION, Perl $], $^X" );
