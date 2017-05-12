#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'autobox::dump' );
}

diag( "Testing autobox::dump $autobox::dump::VERSION, Perl $], $^X" );
