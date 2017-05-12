#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MyModule' );
}

diag( "Testing MyModule $MyModule::VERSION, Perl $], $^X" );
