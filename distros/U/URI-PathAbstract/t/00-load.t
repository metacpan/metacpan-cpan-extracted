#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URI::PathAbstract' );
}

diag( "Testing URI::PathAbstract $URI::PathAbstract::VERSION, Perl $], $^X" );
