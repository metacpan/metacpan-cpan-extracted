#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Writer::Nest' );
}

diag( "Testing XML::Writer::Nest $XML::Writer::Nest::VERSION, Perl $], $^X" );
