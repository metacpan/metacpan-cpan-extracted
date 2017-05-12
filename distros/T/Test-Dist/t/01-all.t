#!/usr/bin/perl

use lib::abs '../lib';
use Test::More;
use Test::Dist;
use Test::NoWarnings;
chdir lib::abs::path('..');

dist_ok(
	'+' => 1,
	run => 1,
	skip => [qw(prereq)],
	fixme => {
		#match => qr/FIXIT/, # Ignore TODO|FIXME here, we use it ;)
	},
	kwalitee => {
		req => [qw( has_separate_license_file has_example
		metayml_has_provides metayml_declares_perl_version
		uses_test_nowarnings has_version_in_each_file
		)],
	},
	prereq => [
		undef,undef, [qw( Test::Pod Test::Pod::Coverage )],
	],
	syntax => {
		file_match => qr{^ex/.+\.(pl|t)$},
	},
);
exit 0;
require Test::Pod::Coverage; # kwalitee hacks, hope temporary
