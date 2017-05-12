#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URI::Based' ) || print "Bail out!\n";
}

diag( "Testing URI::Based $URI::Based::VERSION, Perl $], $^X" );
