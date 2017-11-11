#!perl -T

use strict;
use warnings;
use Test::Most;
use Test::URI;

FINDAGRAVE: {
	unless(-e 't/online.enabled') {
		plan skip_all => 'On-line tests disabled';
	} else {
		plan tests => 14;

		use_ok('WWW::Scrape::FindaGrave');
		my $f = WWW::Scrape::FindaGrave->new({
			firstname => 'Daniel',
			lastname => 'Culmer',
			country => 'England',
			date_of_death => 1862
		});
		ok(defined $f);
		ok($f->isa('WWW::Scrape::FindaGrave'));

		while(my $link = $f->get_next_entry()) {
			diag($link);
			uri_host_ok($link, 'old.findagrave.com');
		}
		ok(!defined($f->get_next_entry()));

		$f = WWW::Scrape::FindaGrave->new({
			firstname => 'xyzzy',
			lastname => 'plugh',
			country => 'Canada',
			date_of_birth => 1862
		});

		ok(defined $f);
		ok($f->isa('WWW::Scrape::FindaGrave'));
		ok(!defined($f->get_next_entry()));

		$f = WWW::Scrape::FindaGrave->new({
			firstname => 'Daniel',
			middlename => 'John',
			lastname => 'Culmer',
			country => 'England',
			date_of_death => 1862
		});
		ok(defined $f);
		ok($f->isa('WWW::Scrape::FindaGrave'));
		ok(!defined($f->get_next_entry()));

		$f = WWW::Scrape::FindaGrave->new({
			firstname => 'Daniel',
			lastname => 'Culmer',
			country => 'United States',
			date_of_death => 1862
		});
		ok(defined $f);
		ok($f->isa('WWW::Scrape::FindaGrave'));
		ok(!defined($f->get_next_entry()));
	}
}
