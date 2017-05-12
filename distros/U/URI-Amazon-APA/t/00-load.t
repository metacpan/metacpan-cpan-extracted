#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URI::Amazon::APA' );
}

diag( "Testing URI::Amazon::APA $URI::Amazon::APA::VERSION, Perl $], $^X" );
