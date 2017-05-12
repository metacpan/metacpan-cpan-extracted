#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tkx::Scrolled' );
}

diag( "Testing Tkx::Scrolled $Tkx::Scrolled::VERSION, Perl $], $^X" );
