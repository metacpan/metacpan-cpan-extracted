#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Sprint' ) || BAIL_OUT( 'could not load' );
}

diag( "Testing WebService::Sprint $WebService::Sprint::VERSION, Perl $], $^X" );
