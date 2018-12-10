#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Text::Trac',
    AUTHOR             => q{Gosuke Miyashita, <gosukenator at gmail.com>},
    VERSION_FROM       => 'lib/Text/Trac.pm',
    ABSTRACT_FROM      => 'lib/Text/Trac.pm',
    LICENSE            => 'perl',
    EXE_FILES          => [ 'script/trac2html' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '1.001014',
        'Test::Base' => 0,
    },
    PREREQ_PM                  => {
        'UNIVERSAL::require'       => 0,
        'Class::Accessor::Fast'    => 0,
        'Class::Data::Inheritable' => 0,
        'Tie::IxHash'              => 0,
        'List::MoreUtils'          => 0,
        'HTML::Entities'           => 0,
        'Path::Tiny'               => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Trac-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Text-Trac.git',
                web  => 'https://github.com/manwar/Text-Trac',
            },
        }})
     : ()
    ),
);
