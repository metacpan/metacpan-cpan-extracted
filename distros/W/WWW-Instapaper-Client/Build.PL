#!/usr/bin/perl
use strict; use warnings;
use Module::Build;
my $build = Module::Build->new (
	module_name => 'WWW::Instapaper::Client',
	license     => 'perl',
	requires    => {
		'perl'  => '5.6.0',
		'LWP::UserAgent' => '0',
		'HTTP::Request::Common' => '0',
		'Crypt::SSLeay' => '0',
		'Class::Base'   => '0',
	},
	build_requires => {
		'Test::Harness' => '0',
		'Test::More'    => '0',
	},
);

$build->create_build_script;
		
