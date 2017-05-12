#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Util::Properties' );
}

diag( "Testing Util::Properties $Util::Properties::VERSION, Perl $], $^X" );
