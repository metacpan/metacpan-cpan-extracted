#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tie::Array::AsHash' ) || BAIL_OUT "Couldn't load Tie::Array::AsHash";
}

diag( "Testing Tie::Array::AsHash $Tie::Array::AsHash::VERSION, Perl $], $^X" );
