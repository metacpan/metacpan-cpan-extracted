#!perl -T
use 5.008_005;
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'cet' ) || print "Bail out!\n";
}

diag( "Testing cet $cet::VERSION, Perl $], $^X" );
