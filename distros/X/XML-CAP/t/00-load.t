#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::CAP' );
}

diag( "Testing XML::CAP $XML::CAP::VERSION, Perl $], $^X" );
