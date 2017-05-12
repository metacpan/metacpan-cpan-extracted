#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Lazy' );
}

diag( "Testing Test::Lazy $Test::Lazy::VERSION, Perl $], $^X" );
