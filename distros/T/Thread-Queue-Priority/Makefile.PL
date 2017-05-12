#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Thread::Queue::Priority',
    'AUTHOR'        => 'Paul Lockaby <plockaby AT cpan DOT org>',
    'VERSION_FROM'  => 'lib/Thread/Queue/Priority.pm',
    'ABSTRACT_FROM' => 'lib/Thread/Queue/Priority.pm',
    'PREREQ_PM'     => {
        'threads::shared'   => 1.21,
        'Scalar::Util'      => 1.10,
        'Test::More'        => 0.50,
    },
    'INSTALLDIRS'   => (($] < 5.011) ? 'perl' : 'site'),

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),
);

