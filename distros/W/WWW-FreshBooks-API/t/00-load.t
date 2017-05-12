#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::FreshBooks::API' );
}

diag( "Testing WWW::FreshBooks::API $WWW::FreshBooks::API::VERSION, Perl $], $^X" );
