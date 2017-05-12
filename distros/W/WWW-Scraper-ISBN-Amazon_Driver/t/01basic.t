#!/usr/bin/perl -w
use strict;

#########################

use Test::More tests => 3;

BEGIN {
	use_ok "WWW::Scraper::ISBN::Amazon_Driver";
	use_ok "WWW::Scraper::ISBN::AmazonUS_Driver";
	use_ok "WWW::Scraper::ISBN::AmazonUK_Driver";
}

#########################
