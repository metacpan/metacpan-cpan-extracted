#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::TBA::API' );
}

diag( "Testing WWW::TBA::API $WWW::TBA::API::VERSION, Perl $], $^X" );
