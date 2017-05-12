#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Thread::Queue::MaxSize',
    'AUTHOR'        => 'Paul Lockaby <plockaby AT cpan DOT org>',
    'VERSION_FROM'  => 'lib/Thread/Queue/MaxSize.pm',
    'ABSTRACT_FROM' => 'lib/Thread/Queue/MaxSize.pm',
    'PREREQ_PM'     => {
        'threads::shared'   => 1.21,
        'Scalar::Util'      => 1.10,
        'Test::More'        => 0.50,
        'Test::Exception'   => 0.31,
        'Thread::Queue'     => 3.03,
    },
    'INSTALLDIRS'   => (($] < 5.011) ? 'perl' : 'site'),

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),
);

