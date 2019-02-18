#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::Google::DistanceMatrix',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/Google/DistanceMatrix.pm',
    ABSTRACT_FROM      => 'lib/WWW/Google/DistanceMatrix.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'                    => '2.000000',
        'namespace::autoclean'   => '0.28',
        'JSON'                   => '2.53',
        'WWW::Google::UserAgent' => '0.23'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Google-DistanceMatrix-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WWW::Google::DistanceMatrix'          => { file => 'lib/WWW/Google/DistanceMatrix.pm',        version => '0.21' },
            'WWW::Google::DistanceMatrix::Params'  => { file => 'lib/WWW/Google/DistanceMatrix/Params.pm', version => '0.21' },
            'WWW::Google::DistanceMatrix::Result'  => { file => 'lib/WWW/Google/DistanceMatrix/Result.pm', version => '0.21' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/WWW-Google-DistanceMatrix.git',
                web  => 'https://github.com/manwar/WWW-Google-DistanceMatrix',
            },
        }})
     : ()
    ),
);
