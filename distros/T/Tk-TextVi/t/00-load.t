#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tk::TextVi' );
}

diag( "Testing Tk::TextVi $Tk::TextVi::VERSION, Perl $], $^X" );
