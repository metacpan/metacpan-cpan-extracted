#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tiny::Prof' ) || print "Bail out!\n";
}

diag( "Testing Tiny::Prof $Tiny::Prof::VERSION, Perl $], $^X" );
