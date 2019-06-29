#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Console' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Console $Mojo::Console::VERSION, Perl $], $^X" );
