#!/usr/bin/perl -w

use strict;

use Module::Build;

my $b = Module::Build->new(
	module_name => 'Test::TAP::HTMLMatrix',
	license => 'perl',
	requires => {
		'perl'				=> '>= 5.008',
		'Test::TAP::Model'	=> '>= 0.08',
		'Petal'				=> 0,
		'Petal::Utils'		=> 0,
		'URI::file'			=> 0,
	},
	build_requires => {
		'Test::More' => 0,
	},
	create_makefile_pl => 'traditional',
	sign => 1,
);

$b->add_build_element("html");
$b->add_build_element("css");

$b->create_build_script;

