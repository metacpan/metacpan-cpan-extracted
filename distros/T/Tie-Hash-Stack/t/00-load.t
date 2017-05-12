#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tie::Hash::Stack' ) || BAIL_OUT("Cannot load Tie::Hash::Stack");
}

diag( "Testing Tie::Hash::Stack $Tie::Hash::Stack::VERSION, Perl $], $^X" );
