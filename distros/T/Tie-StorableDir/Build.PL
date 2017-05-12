#!/usr/bin/perl
use 5.008;
use Module::Build;
my $build = Module::Build->new(
	module_name        => 'Tie::StorableDir',
	dist_version_from  => 'lib/Tie/StorableDir.pm',
	dist_author        => 'Bryan Donlan <bdonlan@gmail.com>',
	license            => 'perl',
	requires           => {
        Carp                    => 0,
		'File::Spec'            => 0,
		'File::Spec::Functions' => 0,
		'Storable'              => 0,
		'IO::Dir'               => 0,
		'Tie::Hash'             => 0,
	},
	create_makefile_pl => 'passthrough',
	script_files => [glob('bin/*.pl')],
);
$build->create_build_script();
