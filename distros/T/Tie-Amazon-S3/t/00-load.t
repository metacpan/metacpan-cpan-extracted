#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::Amazon::S3' );
}

diag( "Testing Tie::Amazon::S3 $Tie::Amazon::S3::VERSION, Perl $], $^X" );
