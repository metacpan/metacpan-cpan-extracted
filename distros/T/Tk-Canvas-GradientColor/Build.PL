use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
	module_name        => 'Tk::Canvas::GradientColor',
	license            => 'perl',
	dist_author        => q{Djibril Ousmanou <djibel@cpan.org>},
	dist_version_from  => 'lib/Tk/Canvas/GradientColor.pm',
	release_status     => 'stable',
	configure_requires => {
		'Module::Build' => 0,
	},
	'build_requires' => {
		'Test::More' => 0,
		'POSIX'      => 0,
		'Tk'         => 800,
	},
	add_to_cleanup     => ['Tk-Canvas-GradientColor-*'],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
