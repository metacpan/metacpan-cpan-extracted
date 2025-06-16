#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

Module::Build->new(

	build_requires => {
		'File::Slurp' => 0,
		'Test::More'  => 0,
	},
	configure_requires => {
		'Module::Build' => 0.40,
	},
	module_name => 'Travel::Status::DE::VRR',
	license     => 'perl',
	recommends  => {
		'Cache::File'   => 0,
		'GIS::Distance' => 0,
	},
	requires    => {
		'perl'                       => '5.10.1',
		'Carp'                       => 0,
		'Class::Accessor'            => 0,
		'DateTime'                   => 0,
		'DateTime::Format::Strptime' => 0,
		'Getopt::Long'               => 0,
		'JSON'                       => 0,
		'List::Util'                 => 0,
		'LWP::UserAgent'             => 0,
		'LWP::Protocol::https'       => 0,
	},
	sign       => 1,
	meta_merge => {
		resources =>
		  { repository => 'https://github.com/derf/Travel-Status-DE-VRR' }
	},
)->create_build_script();
