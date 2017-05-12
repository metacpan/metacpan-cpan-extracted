#!/usr/bin/env perl

use 5.008;
use strict;
use warnings 'all';

# MODULE IMPORTS
use Module::Build 0.31;

# Create Module::Build object
my $build = Module::Build->new(
	module_name => 'URI::pack',
	license     => 'perl',
	dist_author => 'Douglas Christopher Wilson <doug@somethingdoug.com>',

	meta_merge => {
		resources => {
			homepage   => 'http://github.com/dougwilson/perl5-uri-pack/',
			repository => 'git://github.com/dougwilson/perl5-uri-pack.git',
		},
		no_index => {
			directory => [qw/inc t xt/],
		},
	},

	# Module that are required for tests in t/
	build_requires => {
		'Test::More'     => 0,
		'Test::Most'     => 0,
		'Test::Requires' => '0.02',
	},

	# Module that are required
	requires => {
		'perl'             => '5.008003',
		'Carp'             => 0,
		'Const::Fast'      => 0,
		'URI'              => 0,
		'namespace::clean' => 0,
		'parent'           => 0,
	},

	# Enable tests to be in multi-level directories
	recursive_test_files => 1,

	# Create a LICENSE file
	create_license => 1,

	test_files => 't/*.t xt/*.t',
);

$build->create_build_script;

exit 0;
