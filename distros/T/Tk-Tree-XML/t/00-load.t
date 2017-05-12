#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tk::Tree::XML' );
}

diag( "Testing Tk::Tree::XML $Tk::Tree::XML::VERSION, Perl $], $^X" );
