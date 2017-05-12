#! perl -w
use v5.10.1;
use strict;

die "OS unsupported" if $^O eq 'openbsd';

use ExtUtils::MakeMaker 6.47;

WriteMakefile(
    ABSTRACT_FROM => 'lib/lc_time.pm',
    NAME          => 'lc_time',
    VERSION_FROM  => 'lib/lc_time.pm',

    PREREQ_PM => {
        'Encode' => 0,
        'POSIX'  => 0,
        'parent' => 0,
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.56,
    },

    BUILD_REQUIRES => {
        'Test::More'       => 0.96,
        'Test::NoWarnings' => 0,
    },

    MIN_PERL_VERSION => 5.010001,
    META_ADD => {
        'meta-spec' => {
            version => 2,
        },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git@github.com:abeltje/lc_time.git',
                web  => 'https://github.com/abeltje/lc_time',
            },
        },
    },
);
