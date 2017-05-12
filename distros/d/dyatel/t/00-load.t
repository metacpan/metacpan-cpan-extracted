#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dyatel' );
}

diag( "Testing Dyatel $Dyatel::VERSION, Perl $], $^X" );
