use 5.008;
use strict;
use warnings 'all';

use Module::Build 0.31;

my $build = Module::Build->new(
	module_name => 'Test::Override::UserAgent',
	license     => 'perl',
	dist_author => 'Douglas Christopher Wilson <doug@somethingdoug.com>',

	meta_merge => {
		resources => {
			homepage   => 'http://github.com/dougwilson/perl5-test-override-useragent/',
			repository => 'git://github.com/dougwilson/perl5-test-override-useragent.git',
		},
		no_index => {
			directory => [qw/inc t xt/],
		},
	},

	# Modules that are required for this script
	configure_requires => {
		'Module::Build' => '0.31',
	},

	# Modules that are required for tests in t/
	build_requires => {
		'HTTP::Request'   => 0,
		'HTTP::Response'  => 0,
		'IO::String'      => 0,
		'LWP::UserAgent'  => 0,
		'Sub::Install'    => '0.90',
		'Test::Fatal'     => 0,
		'Test::More'     => '0.88',
		'Test::Requires' => '0.02',
	},

	# Modules that are required
	requires => {
		'perl'              => '5.008001',
		'Carp'              => 0,
		'Clone'             => 0,
		'HTTP::Config'      => '5.815',
		'HTTP::Date'        => 0,
		'HTTP::Headers'     => 0,
		'HTTP::Response'    => 0,
		'HTTP::Status'      => '5.817',
		'LWP::Protocol'     => 0,
		'LWP::UserAgent'    => 0,
		'Scalar::Util'      => 0,
		'Sub::Install'      => '0.90',
		'Sub::Override'     => 0,
		'Try::Tiny'         => 0,
		'URI'               => 0,
		'namespace::clean'  => '0.04',
	},

	# The above requirements are static
	dynamic_config => 0,

	# Enable tests to be in multi-level directories
	recursive_test_files => 1,

	# Create a LICENSE file
	create_license => 1,

	# Sign the distribution
	sign => 1,

	test_files => 't/*.t t/*/*.t xt/*.t',
);

$build->create_build_script;
