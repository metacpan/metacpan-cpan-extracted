#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'eGuideDog::Festival' );
}

diag( "Testing eGuideDog::Festival $eGuideDog::Festival::VERSION, Perl $], $^X" );
