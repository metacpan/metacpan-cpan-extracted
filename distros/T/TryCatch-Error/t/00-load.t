#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TryCatch::Error' );
}

diag( "Testing TryCatch::Error $TryCatch::Error::VERSION, Perl $], $^X" );
