#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TkUtil::Gui' );
}

diag( "Testing TkUtil::Gui $TkUtil::Gui::VERSION, Perl $], $^X" );
