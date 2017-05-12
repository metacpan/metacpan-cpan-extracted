#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::GSA' ) || print "Bail out!\n";
}

diag( "Testing XML::GSA $XML::GSA::VERSION, Perl $], $^X" );
