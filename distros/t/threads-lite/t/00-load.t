#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'threads::lite' );
}

diag( "Testing threads::lite $threads::lite::VERSION, Perl $], $^X" );
