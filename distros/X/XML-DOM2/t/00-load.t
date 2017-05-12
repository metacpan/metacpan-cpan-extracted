#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::DOM2' );
}

diag( "Testing XML::DOM2 $XML::DOM2::VERSION, Perl $], $^X" );
