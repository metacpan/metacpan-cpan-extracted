#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Functional' );
}

diag( "Testing Test::Functional $Test::Functional::VERSION, Perl $], $^X" );
