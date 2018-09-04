#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Text::MostFreqKDistance',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Text/MostFreqKDistance.pm',
    ABSTRACT_FROM      => 'lib/Text/MostFreqKDistance.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'      => 0,
        'Test::Exception' => 0.43,
    },
    PREREQ_PM => {
        'strict'   => 0,
        'warnings' => 0,
        'parent'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-MostFreqKDistance-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Text::MostFreqKDistance' => { file => 'lib/Text/MostFreqKDistance.pm', version => '0.10' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Text-MostFreqKDistance.git',
                web  => 'https://github.com/manwar/Text-MostFreqKDistance',
            },
        }})
     : ()
    ),
);
