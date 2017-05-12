use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name        => 'XML::FromArrayref',
	license            => 'perl',
	dist_author        => q{Nic Wolff <nic@angel.net>},
	dist_version_from  => 'lib/XML/FromArrayref.pm',
	configure_requires => {
		'Module::Build'   => 0,
	},
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'perl' => 5.006,
		'HTML::Entities' => 0,
		'URI::Escape' => 0,
	},
	add_to_cleanup     => [ 'XML-FromArrayref-*' ],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
