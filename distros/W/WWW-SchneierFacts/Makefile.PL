#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'WWW::SchneierFacts',
	VERSION_FROM => 'lib/WWW/SchneierFacts.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Moose' => 0,
		'Web::Scraper' => 0,
		'namespace::clean' => '0.08',
		'URI' => 0,
	},
);

