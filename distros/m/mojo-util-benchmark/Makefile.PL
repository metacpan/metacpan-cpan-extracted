#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojo::Util::Benchmark',
    AUTHOR           => q{Adrian Crisan <adrian.crisan88@gmail.com>},
    VERSION_FROM     => 'lib/Mojo/Util/Benchmark.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Util/Benchmark.pm',
    LICENSE          => 'MIT',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious' => 0,
        'Test::More' => 0,
        'Time::HiRes' => 0,
        'Devel::StackTrace' => 0,
    },
    META_MERGE   => {
        no_index       => {
            directory => ['docs', 't']
        },
        resources => {
            homepage => 'https://aurorasoftware.gitlab.io/mojo-util-benchmark',
            license    => ['https://opensource.org/license/mit'],
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/AuroraSoftware/mojo-util-benchmark.git',
                web  => 'https://gitlab.com/AuroraSoftware/mojo-util-benchmark',
            },
            bugtracker => {
                web => 'https://gitlab.com/AuroraSoftware/mojo-util-benchmark/-/issues'
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojo-Util-Benchmark-*' },
    test  => {TESTS => 't/*.t t/*/*.t'},
);
