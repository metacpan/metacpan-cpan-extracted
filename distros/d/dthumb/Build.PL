#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	build_requires => {
		'Test::More' => 0,
		'Test::Compile' => 0,
		'Test::Pod' => 0,
	},
	dist_abstract => 'Generate Thumbnails + Index for a set of images',
	dist_name => 'dthumb',
	module_name => 'App::Dthumb',
	license => 'unrestricted',
	PL_files => {
		'lib/App/Dthumb/Data.pm.PL' => 'lib/App/Dthumb/Data.pm',
	},
	requires => {
		'perl' => '5.10.0',
		'autodie' => 0,
		'Cwd' => 0,
		'Data::Section' => 0,
		'Getopt::Long' => 0,
		'Image::Imlib2' => 0,
		'IO::Handle' => 0,
		'MIME::Base64' => 0,
		'Time::Progress' => 0,
	},
	sign => 1,
);
$build->create_build_script();
