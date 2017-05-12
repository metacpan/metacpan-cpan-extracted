#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Video::Streamer' );
}

diag( "Testing WWW::Video::Streamer $WWW::Video::Streamer::VERSION, Perl $], $^X" );
