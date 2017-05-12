#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Spice' );
}

diag( "Testing XML::Spice $XML::Spice::VERSION, Perl $], $^X" );
