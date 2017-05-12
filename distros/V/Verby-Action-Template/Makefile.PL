#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Verby::Action::Template',
	VERSION_FROM => 'lib/Verby/Action/Template.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
        'Verby' => '0.04',
        'Template' => 0,
        'Test::use::ok' => 0,
        'Test::Exception' => 0,
        'Test::MockObject' => 0,
	},
);

