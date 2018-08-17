#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'overload::x' ) || print "Bail out!\n";
}

diag( "Testing overload::x $overload::x::VERSION, Perl $], $^X" );
