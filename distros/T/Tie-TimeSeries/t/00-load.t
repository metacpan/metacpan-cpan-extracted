#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tie::TimeSeries' ) || print "Bail out!\n";
}

diag( "Testing Tie::TimeSeries $Tie::TimeSeries::VERSION, Perl $], $^X" );
