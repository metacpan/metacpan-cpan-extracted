#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'VisionDB::Read' );
}

diag( "Testing VisionDB::Read $VisionDB::Read::VERSION, Perl $], $^X" );
