#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URI::http::Dump' );
}

diag( "Testing URI::http::Dump $URI::http::Dump::VERSION, Perl $], $^X" );
