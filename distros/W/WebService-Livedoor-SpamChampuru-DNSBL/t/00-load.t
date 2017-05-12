#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::Livedoor::SpamChampuru::DNSBL' );
}

diag( "Testing WebService::Livedoor::SpamChampuru::DNSBL $WebService::Livedoor::SpamChampuru::DNSBL::VERSION, Perl $], $^X" );
