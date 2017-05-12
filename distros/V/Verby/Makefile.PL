#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile(
	NAME         => 'Verby',
	VERSION_FROM => 'lib/Verby.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Set::Object'         => '1.17',
		'Moose'               => '0.40',
		'MooseX::LogDispatch' => '1.1001',
		'Log::Dispatch'       => '2.21',
		'List::MoreUtils'     => 0,
		'Class::Inspector'    => 0,
		'POE'                 => '0.37',
		'File::Path'          => 0, #  MkPath
		'POE::Component::ResourcePool' => '0.03',

		# testing
		'Test::More'         => 0,
		'Test::MockObject'   => 0,
		'Test::Deep'         => 0,
		'Test::Exception'    => 0,
		'Test::use::ok'      => 0,
		'File::Temp'         => 0,
		'Hash::AsObject'     => 0,
		'Directory::Scratch' => 0,
	},
);

