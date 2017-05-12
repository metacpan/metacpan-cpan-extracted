#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Trivial' );
}

diag( "Testing XML::Trivial $XML::Trivial::VERSION, Perl $], $^X" );
