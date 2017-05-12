#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::Snap' ) || print "Bail out!\n";
}

diag( "Testing XML::Snap $XML::Snap::VERSION, Perl $], $^X" );
