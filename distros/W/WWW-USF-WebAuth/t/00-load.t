#!/usr/bin/env perl

use 5.008003;
use strict;
use warnings 'all';

use Test::More; # Will plan tests later

# Modules in this distribution
my @module = qw(
	WWW::USF::WebAuth
);

# Modules to print the version number of
my @display = qw(
	Moose
	Class::MOP
	Authen::CAS::External
);

# Show perl version in test output
diag(sprintf 'Perl %s', $]);

for my $module (@display) {
	my $version = eval qq{require $module; \$${module}::VERSION};
	diag($@ ? $@ : "$module $version");
}

# Plan the tests for the number of modules
plan tests => scalar @module;

for my $module (@module) {
	use_ok($module) or BAIL_OUT("Unable to load $module");
}

exit 0;
