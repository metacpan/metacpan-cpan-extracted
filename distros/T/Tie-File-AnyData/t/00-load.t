#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::File::AnyData' );
}

diag( "Testing Tie::File::AnyData $Tie::File::AnyData::VERSION, Perl $], $^X" );
