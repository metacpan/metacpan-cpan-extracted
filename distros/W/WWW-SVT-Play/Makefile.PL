#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME => 'WWW::SVT::Play',
	AUTHOR => 'Olof Johansson <olof@cpan.org>',
	LICENSE => 'perl',
	ABSTRACT_FROM => 'lib/WWW/SVT/Play.pod',
	VERSION_FROM => 'lib/WWW/SVT/Play/Video.pm',
	SIGN => 1,
	EXE_FILES => ['bin/svtplay'],

	MIN_PERL_VERSION => '5.10.1',

	PREREQ_PM => {
		'LWP::UserAgent' => 0,
		'JSON' => 0,
		'URI' => 0,
		'URI::QueryParam' => 0,
		'URI::Escape' => 0,

		# used in tests
		'Test::Trap' => 0,
		'File::Slurp' => 0,
	},
);

