#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Mechanize::Cached::GZip' );
}

diag( "Testing WWW::Mechanize::Cached::GZip $WWW::Mechanize::Cached::GZip::VERSION, Perl $], $^X" );
