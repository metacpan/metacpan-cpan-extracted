#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Calendar' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Calendar $Mojo::Calendar::VERSION, Perl $], $^X" );
