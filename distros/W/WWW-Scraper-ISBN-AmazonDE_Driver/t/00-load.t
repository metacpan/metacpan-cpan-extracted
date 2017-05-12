#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Scraper::ISBN::AmazonDE_Driver' );
}

diag( "Testing WWW::Scraper::ISBN::AmazonDE_Driver $WWW::Scraper::ISBN::AmazonDE_Driver::VERSION, Perl $], $^X" );
