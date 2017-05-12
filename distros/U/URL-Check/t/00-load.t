#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'URL::Check' ) || print "Bail out!\n";
}

diag( "Testing URL::Check $URL::Check::VERSION, Perl $], $^X" );
