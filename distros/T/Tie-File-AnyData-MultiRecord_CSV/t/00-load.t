#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::File::AnyData::MultiRecord_CSV' );
}

diag( "Testing Tie::File::AnyData::MultiRecord_CSV $Tie::File::AnyData::MultiRecord_CSV::VERSION, Perl $], $^X" );
