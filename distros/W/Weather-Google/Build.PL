#!/usr/bin/perl

use Module::Build;
use strict;
use warnings;

my $build = Module::Build->new (
	perl => 5.006,
	module_name => 'Weather::Google',
	license => 'perl',
	build_requires => {
		'Test::More'   => 0,
		'Test::Simple' => 0,
		'Test::Pod'    => 0,
        'Test::Warn'   => 0,
    },
	requires => {
		'LWP::Simple'  => 0,
		'XML::Simple'  => 0,
		'Carp'         => 0,
	},
);
$build->create_build_script;
