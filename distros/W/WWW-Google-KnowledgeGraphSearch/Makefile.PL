#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::Google::KnowledgeGraphSearch',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/Google/KnowledgeGraphSearch.pm',
    ABSTRACT_FROM      => 'lib/WWW/Google/KnowledgeGraphSearch.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM  => {
        'Moo'                    => '2.000000',
        'namespace::autoclean'   => '0.28',
        'URI'                    => '1.65',
        'WWW::Google::UserAgent' => '0.21',
        'Type::Tiny'             => '1.000005',
        'JSON'                   => '2.90',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Google-KnowledgeGraphSearch-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WWW::Google::KnowledgeGraphSearch'         => { file => 'lib/WWW/Google/KnowledgeGraphSearch.pm'       , version => '0.04' },
            'WWW::Google::KnowledgeGraphSearch::Result' => { file => 'lib/WWW/Google/KnowledgeGraphSearch/Result.pm', version => '0.04' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/WWW-Google-KnowledgeGraphSearch.git',
                web  => 'https://github.com/manwar/WWW-Google-KnowledgeGraphSearch',
            },
        }})
     : ()
    ),
);
