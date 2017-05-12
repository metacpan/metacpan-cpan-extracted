#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Spew' );
}

diag( "Testing XML::Spew $XML::Spew::VERSION, Perl $], $^X" );
