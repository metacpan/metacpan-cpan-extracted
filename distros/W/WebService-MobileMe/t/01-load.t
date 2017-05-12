#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::MobileMe' );
}

diag( "Testing WebService::MobileMe $WebService::MobileMe::VERSION, Perl $], $^X" );
