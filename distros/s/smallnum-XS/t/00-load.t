#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'smallnum::XS' ) || print "Bail out!\n";
}

diag( "Testing smallnum::XS $smallnum::XS::VERSION, Perl $], $^X" );
