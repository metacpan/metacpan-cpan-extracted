#!perl -w

use strict;
use warnings;
use Test::Most;
use Test::URI;

BILLIONGRAVES: {
	unless(-e 't/online.enabled') {
		plan skip_all => 'On-line tests disabled';
	} else {
		plan tests => 15;

		use_ok('WWW::Scrape::BillionGraves');
		my $f = WWW::Scrape::BillionGraves->new({
			firstname => 'Isaac',
			lastname => 'Horne',
			country => 'England',
			date_of_death => 1964,
		});
		ok(defined $f);
		ok($f->isa('WWW::Scrape::BillionGraves'));

		my $count = 0;
		while(my $link = $f->get_next_entry()) {
			diag($link);
			uri_host_ok($link, 'billiongraves.com');
			$count++;
		}
		ok(!defined($f->get_next_entry()));
		ok($count > 0);

		$f = WWW::Scrape::BillionGraves->new({
			firstname => 'xyzzy',
			lastname => 'plugh',
			country => 'Canada',
			date_of_birth => 1862
		});

		ok(defined $f);
		ok($f->isa('WWW::Scrape::BillionGraves'));
		ok(!defined($f->get_next_entry()));

		$f = WWW::Scrape::BillionGraves->new({
			firstname => 'Daniel',
			middlename => 'John',
			lastname => 'Culmer',
			country => 'England',
			date_of_death => 1862
		});
		ok(defined $f);
		ok($f->isa('WWW::Scrape::BillionGraves'));
		ok(!defined($f->get_next_entry()));

		$f = WWW::Scrape::BillionGraves->new({
			firstname => 'Daniel',
			lastname => 'Culmer',
			country => 'United States',
			date_of_death => 1862
		});
		ok(defined $f);
		ok($f->isa('WWW::Scrape::BillionGraves'));
		ok(!defined($f->get_next_entry()));
	}
}
