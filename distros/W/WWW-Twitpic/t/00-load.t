#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'WWW::Twitpic' );
	use_ok( 'WWW::Twitpic::API' );
}

diag( "Testing WWW::Twitpic $WWW::Twitpic::VERSION, Perl $], $^X" );
