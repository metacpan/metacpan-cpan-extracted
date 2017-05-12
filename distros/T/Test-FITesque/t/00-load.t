#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::FITesque' );
}

diag( "Testing Test::FITesque $Test::FITesque::VERSION, Perl $], $^X" );
