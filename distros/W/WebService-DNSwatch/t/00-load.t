#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::DNSwatch' );
}

diag( "Testing WebService::DNSwatch $WebService::DNSwatch::VERSION, Perl $], $^X" );
