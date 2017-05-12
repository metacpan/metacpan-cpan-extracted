#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Tie::ToObject',
	VERSION_FROM => 'lib/Tie/ToObject.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Tie::RefHash' => 0, # core, used in test
		'Test::use::ok' => 0,
		'Test::More' => 0,
		'Scalar::Util' => 0,
	},
);

