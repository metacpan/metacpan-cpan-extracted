use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Tkx::Scrolled',
	license             => 'perl',
	dist_author         => 'Michael J. Carman <mjcarman@cpan.org>',
	dist_version_from   => 'lib/Tkx/Scrolled.pm',
	requires            => {
		'Tkx'  => 0,
	},
	build_requires => {
		'Test::More' => 0,
	},
	add_to_cleanup      => [ 'Tkx-Scrolled-*' ],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
