#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tie::Array::Cavity' ) || print "Bail out!\n";
}

diag( "Testing Tie::Array::Cavity $Tie::Array::Cavity::VERSION, Perl $], $^X" );
