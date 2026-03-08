#!/usr/bin/env perl

use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Spelling::Stopwords',
    AUTHOR              => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM        => 'lib/Test/Spelling/Stopwords.pm',
    ABSTRACT_FROM       => 'lib/Test/Spelling/Stopwords.pm',
    LICENSE             => 'artistic_2',
    EXE_FILES           => [ 'script/gen-stopwords' ],
    MIN_PERL_VERSION    => 5.014,
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES      => {
        'Test::More'    => 0,
    },
    PREREQ_PM           => {
        'Pod::Usage'    => 0,
        'File::Find'    => 0,
        'File::Spec'    => 0,
        'Test::Builder' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Test-Spelling-Stopwords-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Test::Spelling::Stopwords' => {
                file    => 'lib/Test/Spelling/Stopwords.pm',
                version => MM->parse_version('lib/Test/Spelling/Stopwords.pm')
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Test-Spelling-Stopwords.git',
                web  => 'https://github.com/manwar/Test-Spelling-Stopwords',
            },
            bugtracker => {
                web  => 'https://github.com/manwar/Test-Spelling-Stopwords/issues'
            },
        }})
     : ()
    ),
);
