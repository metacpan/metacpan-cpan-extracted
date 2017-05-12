#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Stickam::API' );
}

diag( "Testing WWW::Stickam::API $WWW::Stickam::API::VERSION, Perl $], $^X" );
