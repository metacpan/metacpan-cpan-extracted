#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'random' );
}

diag( "Testing random $random::VERSION, Perl $], $^X" );
