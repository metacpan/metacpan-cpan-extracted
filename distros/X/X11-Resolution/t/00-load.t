#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'X11::Resolution' );
}

diag( "Testing X11::Resolution $X11::Resolution::VERSION, Perl $], $^X" );
