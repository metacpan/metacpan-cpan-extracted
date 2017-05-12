#!/usr/bin/perl

require 5.6.0;
use strict;
use warnings;
use utf8;
use Module::Build;

Module::Build->new(
	module_name => 'Text::FixedLengthMultiline',
	# I hope one day YAML.pm will correctly encode using UTF-8
	#dist_author => 'Olivier Mengué <dolmen@cpan.org>',
	dist_author => 'Olivier Mengue <dolmen@cpan.org>',
	license => 'perl',
	requires => {
		'perl' => '5.006',
		'Carp' => 0,
		'constant' => 0,
	},
	configure_requires => {
		'Test::More' => 0,
		'Test::NoWarnings' => '1.01',
	},
	meta_add => {
		resources => {
			homepage => 'http://github.com/dolmen/Text-FixedLengthMultiline-perl',
			repository => 'git://github.com/dolmen/Text-FixedLengthMultiline-perl.git',
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-FixedLengthMultiline',
		},
	},
	create_readme => 1,
	create_makefile_pl => 'traditional'
)->create_build_script;
