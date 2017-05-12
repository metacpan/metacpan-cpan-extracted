#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::EditDNS' );
}

diag( "Testing WebService::EditDNS $WebService::EditDNS::VERSION, Perl $], $^X" );
