#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::StatsMix',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/StatsMix.pm',
    ABSTRACT_FROM      => 'lib/WWW/StatsMix.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM  => {
        'JSON' => 0,
        'Moo'  => 0,
        'namespace::clean'      => 0,
        'Throwable'             => 0,
        'LWP::UserAgent'        => 0,
        'HTTP::Request::Common' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-StatsMix-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Manwar/WWW-StatsMix.git',
                web  => 'https://github.com/Manwar/WWW-StatsMix',
            },
        }})
     : ()
    ),
);
