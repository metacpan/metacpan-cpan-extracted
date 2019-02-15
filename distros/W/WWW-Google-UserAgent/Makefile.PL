#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::Google::UserAgent',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/Google/UserAgent.pm',
    ABSTRACT_FROM      => 'lib/WWW/Google/UserAgent.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'                  => '2.000000',
        'namespace::autoclean' => '0.28',
        'HTTP::Tiny'           => '0.043',
        'IO::Socket::SSL'      => '1.56',
        'Net::SSLeay'          => '1.49',
        'Throwable'            => '0.200011',
        'Type::Tiny'           => '1.000005',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Google-UserAgent-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WWW::Google::UserAgent'            => { file => 'lib/WWW/Google/UserAgent.pm',           version => '0.23' },
            'WWW::Google::UserAgent::DataTypes' => { file => 'lib/WWW/Google/UserAgent/DataTypes.pm', version => '0.23' },
            'WWW::Google::UserAgent::Exception' => { file => 'lib/WWW/Google/UserAgent/Exception.pm', version => '0.23' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/WWW-Google-UserAgent.git',
                web  => 'https://github.com/manwar/WWW-Google-UserAgent',
            },
        }})
     : ()
    ),
);
