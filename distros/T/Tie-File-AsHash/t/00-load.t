#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tie::File::AsHash' ) || BAIL_OUT "Couldn't load Tie::File::AsHash";
}

diag( "Testing Tie::File::AsHash $Tie::File::AsHash::VERSION, Perl $], $^X" );
