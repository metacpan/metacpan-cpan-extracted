#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Verby::Action::Untar',
	VERSION_FROM => 'lib/Verby/Action/Untar.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
        'Verby'         => '0.05',
		'Test::use::ok' => 0,
        'Archive::Tar'  => 0,
        'Hash::AsObject' => 0,
        'Test::MockObject' => 0,
        'Log::Dispatch::Config' => 0,
        'Log::Dispatch' => '2.21', # log_and_die
        'Log::Dispatch::Config::TestLog' => 0,
	},
);

