#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::FC2::SpamAPI' );
}

diag( "Testing WebService::FC2::SpamAPI $WebService::FC2::SpamAPI::VERSION, Perl $], $^X" );
