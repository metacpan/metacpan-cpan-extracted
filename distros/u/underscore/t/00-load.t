#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'underscore' );
}

diag( "Testing underscore $underscore::VERSION, Perl $], $^X" );
