#!perl -wT

use strict;

use Test::Most;
use WWW::Scrape::FindaGrave;

NEW: {
	if(-e 't/online.enabled') {
		plan tests => 1;

		my $args = {
			'firstname' => 'john',
			'lastname' => 'smith',
			'date_of_birth' => 1912
		};

		isa_ok(WWW::Scrape::FindaGrave->new($args), 'WWW::Scrape::FindaGrave', 'Creating WWW::Scrape::FindaGrave object');
	} else {
		plan skip_all => 'On-line tests disabled';
	}
}
