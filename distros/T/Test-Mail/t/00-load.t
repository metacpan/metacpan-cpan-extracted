#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Mail' );
}

diag( "Testing Test::Mail $Test::Mail::VERSION, Perl $], $^X" );
