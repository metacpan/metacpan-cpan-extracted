#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Scraper::ISBN::LibUniverIt' );
}

diag( "Testing WWW::Scraper::ISBN::LibUniverIt $WWW::Scraper::ISBN::LibUniverIt::VERSION, Perl $], $^X" );
