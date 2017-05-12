#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Differences' );
}

diag( "Testing Test::Differences $Test::Differences::VERSION, Perl $], $^X" );
