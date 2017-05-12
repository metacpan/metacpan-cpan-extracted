use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name   => 'XML::Stream',
	license       => 'lgpl',
	dist_author   => 'Darian Anthony Patrick <dapatrick@cpan.org>',
	dist_abstract => 'XML stream support library for XMPP-like protocols',

	configure_requires => {
		'Module::Build' => '0.360300',
	},

	build_requires => {
		'Test::More'    => '0.92',
	},

	requires => {
		'perl'          => 'v5.8.0',
		'Authen::SASL'  => 0,
		'Carp'          => 0,
		'Encode'        => 0,
		'FileHandle'    => 0,
		'IO::Select'    => 0,
		'IO::Socket'    => 0,
		'MIME::Base64'  => 0,
		'POSIX'         => 0,
		'Sys::Hostname' => 0,
		'utf8'          => 0,
		'Scalar::Util'  => 0,
	},

	sign               => 1,
	create_license     => 1,
	create_makefile_pl => 'traditional',
	meta_merge => {
		'resources' => {
			'bugtracker' => 'https://github.com/dap/XML-Stream/issues',
			'repository' => 'https://github.com/dap/XML-Stream',
		}
	},
);

$build->create_build_script;
