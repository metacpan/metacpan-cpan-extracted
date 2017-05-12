#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'relative' );
}

diag( "Testing relative $relative::VERSION, Perl $], $^X" );
