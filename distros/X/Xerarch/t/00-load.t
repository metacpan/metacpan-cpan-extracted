#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Xerarch' ) || print "Bail out!\n";
}

diag( "Testing Xerarch $Xerarch::VERSION, Perl $], $^X" );
