#!/usr/bin/perl -w
use strict;

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Scraper::ISBN::ISBNdb_Driver' );
}

diag( "Testing WWW::Scraper::ISBN::ISBNdb_Driver $WWW::Scraper::ISBN::ISBNdb_Driver::VERSION, Perl $], $^X" );
