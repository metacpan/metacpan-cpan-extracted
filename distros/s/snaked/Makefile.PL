#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'snaked',
    'VERSION_FROM'  => 'lib/snaked.pm',
    'ABSTRACT_FROM' => 'lib/snaked.pm',
    'EXE_FILES' => [ 'snaked' ],
    'PREREQ_PM' => {
        'Cwd' => 0,
        'Set::Crontab' => 0,
        'Schedule::Cron::Events' => 0,
        'Storable' => 0,
        'Time::HiRes' => 0,
        'Time::Local' => 0,
        'Yandex::Tools' => 0,
        },
    'AUTHOR' => 'Petya Kohts <petya@kohts.com>',
    );
