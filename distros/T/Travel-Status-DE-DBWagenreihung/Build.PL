#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

Module::Build->new(

	build_requires => {
		'Test::Compile' => 0,
		'Test::More' => 0,
		'Test::Pod' => 0,
	},
	configure_requires => {
		'Module::Build' => 0.40,
	},
	module_name => 'Travel::Status::DE::DBWagenreihung',
	license => 'perl',
	requires => {
		'perl' => '5.20.0',
		'Carp' => 0,
		'Class::Accessor' => 0,
		'Getopt::Long' => 0,
		'JSON' => 0,
		'List::Util' => 0,
		'LWP::UserAgent' => 0,
		'Travel::Status::DE::IRIS' => 1.20,
	},
	sign => 1,
	meta_merge => {
		resources => {
			repository => 'https://github.com/derf/Travel-Status-DE-DBWagenreihung'
		}
	},

)->create_build_script();
