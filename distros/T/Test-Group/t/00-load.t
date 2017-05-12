#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Group' );
}

diag( "Testing Test::Group $Test::Group::VERSION, Perl $], $^X" );
