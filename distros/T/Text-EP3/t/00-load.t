#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::EP3' );
}

diag( "Testing Text::EP3 $Text::EP3::VERSION, Perl $], $^X" );
