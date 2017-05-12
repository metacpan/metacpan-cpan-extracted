#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::MockPackages' );
}

diag( "Testing Test::MockPackages $Test::MockPackages::VERSION, Perl $], $^X" );
