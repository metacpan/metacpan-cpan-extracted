#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'lib::glob' );
}

diag( "Testing lib::glob $lib::glob::VERSION, Perl $], $^X" );
