#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'jQuery::Loader' );
}

diag( "Testing jQuery::Loader $jQuery::Loader::VERSION, Perl $], $^X" );
