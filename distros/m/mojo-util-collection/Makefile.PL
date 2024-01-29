#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojo::Util::Collection',
    AUTHOR           => q{Adrian Crisan <adrian.crisan88@gmail.com>},
    VERSION_FROM     => 'lib/Mojo/Util/Collection.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Util/Collection.pm',
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
            homepage => 'https://aurorasoftware.gitlab.io/mojo-util-collection',
            license    => ['https://opensource.org/license/mit'],
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/AuroraSoftware/mojo-util-collection.git',
                web  => 'https://gitlab.com/AuroraSoftware/mojo-util-collection',
            },
            bugtracker => {
                web => 'https://gitlab.com/AuroraSoftware/mojo-util-collection/-/issues'
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojo-Util-Collection-*' },
    test  => {TESTS => 't/*.t t/*/*.t'},
);
