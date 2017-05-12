use 5.008;
use strict;
use warnings 'all';

use Module::Build 0.31;

my $build = Module::Build->new(
	module_name => 'WWW::USF::Directory',
	license     => 'perl',
	dist_author => 'Douglas Christopher Wilson <doug@somethingdoug.com>',

	meta_merge => {
		resources => {
			homepage   => 'http://github.com/dougwilson/perl5-www-usf-directory/',
			repository => 'git://github.com/dougwilson/perl5-www-usf-directory.git',
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
		'Test::Fatal'               => 0,
		'Test::More'                => '0.94',
		'Test::Override::UserAgent' => 0,
		'Test::Requires'            => '0.02',
		'URI::QueryParam'           => 0,
	},

	# Modules that are required
	requires => {
		'perl'                      => '5.008001',
		'Carp'                      => 0,
		'Const::Fast'               => '0.004',
		'Class::Load'               => 0,
		'HTML::HTML5::Parser'       => '0.101',
		'List::MoreUtils'           => '0.07',
		'Moose'                     => '0.89',
		'MooseX::StrictConstructor' => '0.08',
		'MooseX::Types'             => '0.08',
		'MooseX::Types::Common'     => 0,
		'MooseX::Types::Email'      => 0,
		'MooseX::Types::Moose'      => 0,
		'MooseX::Types::URI'        => 0,
		'Net::SAJAX'                => '0.102',
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
