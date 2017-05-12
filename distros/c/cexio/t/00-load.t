#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'cexio' ) || print "Bail out!\n";
}

diag( "Testing cexio $cexio::VERSION, Perl $], $^X" );
