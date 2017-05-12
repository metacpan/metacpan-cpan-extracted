#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZML' );
}

diag( "Testing ZML $ZML::VERSION, Perl $], $^X" );
