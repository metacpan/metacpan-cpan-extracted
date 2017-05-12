#!/usr/bin/env perl

use 5.008;
use strict;
use warnings 'all';

# MODULE IMPORTS
use Module::Build 0.31;

# Create Module::Build object
my $build = Module::Build->new(
	module_name => 'WWW::USF::WebAuth',
	license     => 'perl',
	dist_author => 'Douglas Christopher Wilson <doug@somethingdoug.com>',

	meta_merge => {
		resources => {
			homepage   => 'http://github.com/dougwilson/perl5-www-usf-webauth/',
			repository => 'git://github.com/dougwilson/perl5-www-usf-webauth.git',
		},
		no_index => {
			directory => [qw/inc t xt/],
		},
	},

	# Module that are required for tests in t/
	build_requires => {
		'Test::Fatal'               => 0,
		'Test::More'                => 0,
		'Test::Requires'            => '0.02',
	},

	# Modules that are required for configuration (this file)
	configure_requires => {
		'Module::Build' => '0.31',
	},

	# Module that are required
	requires => {
		'perl'                      => '5.008003',
		'Authen::CAS::External'     => '0.05',
		'LWP::Protocol::https'      => 0,
		'Moose'                     => '1.03',
		'MooseX::Aliases'           => '0.05',
		'MooseX::StrictConstructor' => '0.09',
		'MooseX::Types'             => '0.08',
		'namespace::clean'          => '0.04',
	},

	# The above requirements are static
	dynamic_config => 0,

	# Enable tests to be in multi-level directories
	recursive_test_files => 1,

	# Create a LICENSE file
	create_license => 1,

	# Sign the distribution
	sign => 1,

	test_files => 't/*.t xt/*.t',
);

$build->create_build_script;

exit 0;

