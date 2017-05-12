#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Netflix::API' );
}

diag( "Testing WWW::Netflix::API $WWW::Netflix::API::VERSION, Perl $], $^X" );
