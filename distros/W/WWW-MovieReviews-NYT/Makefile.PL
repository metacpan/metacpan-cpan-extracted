#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::MovieReviews::NYT',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/MovieReviews/NYT.pm',
    ABSTRACT_FROM      => 'lib/WWW/MovieReviews/NYT.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'HTTP::Request::Common' => '5.824',
        'LWP::UserAgent'        => '2.33',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-MovieReviews-NYT-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Manwar/WWW-MovieReviews-NYT.git',
                web  => 'https://github.com/Manwar/WWW-MovieReviews-NYT',
            },
        }})
     : ()
    ),
);
