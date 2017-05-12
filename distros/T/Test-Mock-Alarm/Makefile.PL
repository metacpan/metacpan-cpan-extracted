#!/usr/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Mock::Alarm',
    AUTHOR              => 'Jeremy Jack <jeremy@rocketscientry.com>',
    VERSION_FROM        => 'lib/Test/Mock/Alarm.pm',
    ABSTRACT_FROM       => 'lib/Test/Mock/Alarm.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 		=> 0,
        'Test::Exception'	=> 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Mock-Alarm-*' },
);
