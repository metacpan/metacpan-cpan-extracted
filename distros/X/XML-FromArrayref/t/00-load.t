#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::FromArrayref' ) || print "Bail out!\n";
}

diag( "Testing XML::FromArrayref $XML::FromArrayref::VERSION, Perl $], $^X" );
