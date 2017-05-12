#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URI::ParseSearchString' );
}

diag( "Testing URI::ParseSearchString $URI::ParseSearchString::VERSION, Perl $], $^X" );
