#!/usr/bin/perl

use lib::abs '../lib';
use Test::NoWarnings;
use Test::More;
use Test::Dist as => 0.01;
chdir lib::abs::path('..');

Test::Dist::dist_ok(
	'+' => 1, # Add one more test to plan due to NoWarnings
	run => 1, # Start condition. By default uses $ENV{TEST_AUTHOR}
	skip => [qw(prereq)], # Skip prereq from testing
	fixme => { # For options, see Test::Fixme
		match => qr/TODO|FIXME|!!!/, # Your own fixme patterns
	},
	kwalitee => {
		req => [qw( has_separate_license_file has_example )], # Optional metrics, that you require to pass
	},
	prereq => [ # For options, see Test::Prereq
		undef,undef,
		[qw( Test::Pod Test::Pod::Coverage )], # Ignore this in prereq list
	]
);
