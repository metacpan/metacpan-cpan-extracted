use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Tie::Tk::Text',
	license             => 'perl',
	dist_author         => 'Michael J. Carman <mjcarman@cpan.org>',
	dist_version_from   => 'lib/Tie/Tk/Text.pm',
	requires            => {
		'Tk'   => 0,
#		'Tkx'  => 0,
	},
	build_requires => {
		'Test::More' => 0,
	},
	add_to_cleanup     => [ 'Tie-Tk-Text-*' ],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
