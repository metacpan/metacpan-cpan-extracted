#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Regression' );
}

diag( "Testing Test::Regression $Test::Regression::VERSION, Perl $], $^X" );
