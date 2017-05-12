#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Quick' );
}

diag( "Testing XML::Quick $XML::Quick::VERSION, Perl $], $^X" );
