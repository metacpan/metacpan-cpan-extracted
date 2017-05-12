#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

Module::Build->new(

	build_requires => {
		'File::Slurp' => 0,
		'Test::More' => 0,
		'Test::Pod' => 0,
		'Test::Fatal' => 0,
	},
	configure_requires => {
		'Module::Build' => 0.40,
	},
	module_name => 'Travel::Status::DE::URA',
	license => 'perl',
	requires => {
		'perl' => '5.10.1',
		'Carp' => 0,
		'Class::Accessor' => 0,
		'DateTime' => 0,
		'DateTime::Format::Duration' => 0,
		'Getopt::Long' => 0,
		'List::MoreUtils' => 0,
		'LWP::UserAgent' => 0,
		'Text::CSV' => 0,
	},
	sign => 1,

)->create_build_script();
