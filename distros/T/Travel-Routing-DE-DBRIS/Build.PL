#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

Module::Build->new(

	build_requires => {
		'Test::Compile' => 0,
		'Test::More'    => 0,
		'Test::Pod'     => 0,
	},
	configure_requires => {
		'Module::Build' => 0.40,
	},
	module_name => 'Travel::Routing::DE::DBRIS',
	license     => 'perl',
	recommends  => {
		'Cache::File' => 0,
	},
	requires => {
		'perl'                                => '5.20.0',
		'Class::Accessor'                     => '0.16',
		'DateTime'                            => 0,
		'DateTime::Duration'                  => 0,
		'DateTime::Format::Strptime'          => 0,
		'Getopt::Long'                        => 0,
		'JSON'                                => 0,
		'List::Util'                          => 0,
		'LWP::UserAgent'                      => 0,
		'LWP::Protocol::https'                => 0,
		'Travel::Status::DE::DBRIS'           => '0.01',
		'Travel::Status::DE::DBRIS::Location' => '0.01',
	},
	script_files => 'bin/',
	sign         => 1,
	meta_merge   => {
		resources =>
		  { repository => 'https://github.com/derf/Travel-Routing-DE-DBRIS' }
	},
)->create_build_script();
