#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Unique' );
}

diag( "Testing Unique $Unique::VERSION, Perl $], $^X" );
