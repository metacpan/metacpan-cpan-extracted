#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::SmugMug::API' );
}

diag( "Testing WWW::SmugMug::API $WWW::SmugMug::API::VERSION, Perl $], $^X" );
