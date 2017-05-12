#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'W3C::XMLSchema' );
}

diag( "Testing W3C::XMLSchema $W3C::XMLSchema::VERSION, Perl $], $^X" );
