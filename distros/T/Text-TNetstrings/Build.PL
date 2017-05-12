use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name          => 'Text::TNetstrings',
	license              => 'mit',
	extra_compiler_flags => qw(-Werror -Wall),
	extra_linker_flags   => ['-lm'],
	configure_requires => {
		'version' => '>=0.77',
		'Module::Build' => 0,
	},
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'perl'         => 5.008,
		'version'      => '>=0.77',
		'Scalar::Util' => 0,
	},
	recommends => {
		'boolean' => 0,
	},
	add_to_cleanup     => [ 'Text-TNetstrings-*' ],
);

$builder->create_build_script();
