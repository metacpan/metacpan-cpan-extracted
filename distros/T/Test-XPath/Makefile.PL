#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Test::XPath',
    AUTHOR             => q{David E. Wheeler <dwheeler@cpan.org>},
    VERSION_FROM       => 'lib/Test/XPath.pm',
    ABSTRACT_FROM      => 'lib/Test/XPath.pm',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '0.70',
    },
    PREREQ_PM           => {
        'Test::Builder' => '0.70',
        'XML::LibXML'   => '1.70',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-XPath-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Test-XPath.git',
                web  => 'https://github.com/manwar/Test-XPath',
            },
            bugtracker => {
                web => 'http://github.com/manwar/test-xpath/issues',
            },
        },
        prereqs => {
            runtime => {
                recommends => {
                    'HTML::Selector::XPath' => '0.06',
                },
            },
        },
    }) : () ),
);
