#!perl -w

use strict;
use warnings;
use Test::Most;

unless($ENV{AUTHOR_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

# eval 'use warnings::unused -global';
eval 'use warnings::unused';
if($@ || ($warnings::unused::VERSION < 0.04)) {
	plan(skip_all => 'warnings::unused >= 0.04 needed for testing');
} else {
	use_ok('WWW::Scrape::BillionGraves');
	new_ok('WWW::Scrape::BillionGraves' => [ firstname => 'Isaac', lastname => 'Horne', 'date_of_death' => '1964' ]);
	plan(tests => 2);
}
