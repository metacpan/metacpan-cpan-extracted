#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Mechanize::GZip' );
}

diag( "Testing WWW::Mechanize::GZip $WWW::Mechanize::GZip::VERSION, Perl $], $^X" );
