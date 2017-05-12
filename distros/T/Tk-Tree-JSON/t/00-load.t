#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tk::Tree::JSON' );
}

diag( "Testing Tk::Tree::JSON $Tk::Tree::JSON::VERSION, Perl $], $^X" );
