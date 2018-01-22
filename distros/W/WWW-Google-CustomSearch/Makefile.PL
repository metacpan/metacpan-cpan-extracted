#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::Google::CustomSearch',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/Google/CustomSearch.pm',
    ABSTRACT_FROM      => 'lib/WWW/Google/CustomSearch.pm',
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
        'JSON'                   => '2.53',
        'URI'                    => '1.65',
        'WWW::Google::UserAgent' => '0.21',
        'Type::Tiny'             => '1.000005'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Google-CustomSearch-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WWW::Google::CustomSearch'          => { file => 'lib/WWW/Google/CustomSearch.pm',         version => '0.37' },
            'WWW::Google::CustomSearch::Item'    => { file => 'lib/WWW/Google/CustomSearch/Item.pm',    version => '0.37' },
            'WWW::Google::CustomSearch::Page'    => { file => 'lib/WWW/Google/CustomSearch/Page.pm',    version => '0.37' },
            'WWW::Google::CustomSearch::Params'  => { file => 'lib/WWW/Google/CustomSearch/Params.pm',  version => '0.37' },
            'WWW::Google::CustomSearch::Request' => { file => 'lib/WWW/Google/CustomSearch/Request.pm', version => '0.37' },
            'WWW::Google::CustomSearch::Result'  => { file => 'lib/WWW/Google/CustomSearch/Result.pm',  version => '0.37' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/WWW-Google-CustomSearch.git',
                web  => 'https://github.com/manwar/WWW-Google-CustomSearch',
            },
        }})
     : ()
    ),
);
