#!/usr/bin/perl -w
use strict;

use Test::More tests => 3;

BEGIN {
	use_ok( 'WWW::Scraper::ISBN' );
	use_ok( 'WWW::Scraper::ISBN::Driver' );
	use_ok( 'WWW::Scraper::ISBN::Record' );
}
