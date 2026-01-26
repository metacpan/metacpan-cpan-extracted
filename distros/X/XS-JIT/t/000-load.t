#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XS::JIT' ) || print "Bail out!\n";
}

diag( "Testing XS::JIT $XS::JIT::VERSION, Perl $], $^X" );
