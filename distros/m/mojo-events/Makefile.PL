#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojo::Events',
    AUTHOR           => q{Adrian Crisan <adrian.crisan88@gmail.com>},
    VERSION_FROM     => 'lib/Mojo/Events.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Events.pm',
    LICENSE          => 'artistic_2',
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
    },
    META_MERGE   => {
        no_index       => {directory => ['t']},
        resources => {
            bugtracker => {
                web => 'https://github.com/crlcu/mojo-events/issues'
            },
            license    => ['https://opensource.org/licenses/MIT'],
            repository => {
                type => 'git',
                url  => 'https://github.com/crlcu/mojo-events.git',
                web  => 'https://github.com/crlcu/mojo-events',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojo-Events-*' },
    test      => {TESTS => 't/*.t'},
);
