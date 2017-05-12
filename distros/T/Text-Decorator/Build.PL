#!/usr/bin/perl -w

use strict;
use warnings;

use Module::Build;

Module::Build->new(
	module_name => 'Text::Decorator',
	license     => 'perl',
	requires    => {
		'UNIVERSAL::require'       => '0.03',
	},
	recommends => { 
     'URI::Find' => 0, 
     'Template'  => 0,
	},
	build_requires => {
		'Test::More'       => '0.47',
		}

)->create_build_script;
