#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'XML::SAX::Simple',
    AUTHOR             => 'Matt Sergeant, <matt@sergeant.org>',
    VERSION_FROM       => 'lib/XML/SAX/Simple.pm',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES     => {
        'Test::More'   => 0,
    },
    PREREQ_PM          => {
        'XML::Simple'         => 2.22,
        'XML::SAX'            => 0.99,
        'XML::Handler::Trees' => 0.02,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-SAX-Simple-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/XML-SAX-Simple.git',
                web  => 'https://github.com/manwar/XML-SAX-Simple',
            },
        }})
     : ()
    ),
);
