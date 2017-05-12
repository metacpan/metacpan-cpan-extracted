#!/usr/bin/perl

use 5.006;
use strict;

use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Unicode::Stringprep',
	'license'	=> 'perl',
	'dist_author'	=> 'Claus Färber <CFAERBER@cpan.org>',
	'dist_abstract' => 'Preparation of Internationalized Strings (RFC 3454)',

	'sign'		=> 1,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

	'requires'	=> {
		'Unicode::Normalize' => 1,
		'perl' => 5.008003,
	},
	'build_requires' => {
		'Test::NoWarnings' => 0,
		'Test::More' => 0,
	},
	'no_index' => {
		'directory' => ['eg'],
	},
	'resources' => {
		'homepage' => 'http://search.cpan.org/dist/Unicode-Stringprep',
		'repository' => 'http://github.com/cfaerber/Unicode-Stringprep',
	},
);

$b->create_build_script;
