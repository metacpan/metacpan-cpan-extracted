#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'iPod::Squish',
	VERSION_FROM => 'lib/iPod/Squish.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	EXE_FILES    => [qw(script/isquish)],
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Parallel::ForkManager' => 0,
		#'Audio::File' => 0,
		'Number::Bytes::Human' => 0,
		'File::Which' => 0,
		'MP3::Info' => 0,
		'FFmpeg::Command' => 0,
		'Moose' => 0,
		'MooseX::LogDispatch' => '1.1001',
		'MooseX::Types::Path::Class' => 0,
	},
);

