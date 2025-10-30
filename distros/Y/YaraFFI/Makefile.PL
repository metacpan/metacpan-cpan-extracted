#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'YaraFFI',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/YaraFFI.pm',
    ABSTRACT_FROM      => 'lib/YaraFFI.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'FFI::Platypus' => 1.00,
        'FFI::CheckLib' => 0,
        'File::Slurp'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t' },
    clean => { FILES => 'YaraFFI-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'YaraFFI'   => {
                file    => 'lib/YaraFFI.pm',
                version => '0.06'
            },
            'YaraFFI::Event' => {
                file    => 'lib/YaraFFI/Event.pm',
                version => '0.06'
            },
            'YaraFFI::Record::YR_MATCH' => {
                file    => 'lib/YaraFFI/Record/YR_MATCH.pm',
                version => '0.06'
            },
            'YaraFFI::Record::YR_META' => {
                file    => 'lib/YaraFFI/Record/YR_META.pm',
                version => '0.06'
            },
            'YaraFFI::Record::YR_RULE' => {
                file    => 'lib/YaraFFI/Record/YR_RULE.pm',
                version => '0.06'
            },
            'YaraFFI::Record::YR_STRING' => {
                file    => 'lib/YaraFFI/Record/YR_STRING.pm',
                version => '0.06'
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/YaraFFI.git',
                web  => 'https://github.com/manwar/YaraFFI',
            },
        }})
     : ()
    ),
);
