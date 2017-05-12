#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Varnish' );
}

diag( "Testing Test::Varnish $Test::Varnish::VERSION, Perl $], $^X" );
