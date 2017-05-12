#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tree::Create::DepthFirst',
    AUTHOR           => q{René Nyffenegger <rene.nyffenegger@adp-gmbh.ch>},
    VERSION_FROM     => 'lib/Tree/Create/DepthFirst.pm',
    ABSTRACT_FROM    => 'lib/Tree/Create/DepthFirst.pm',
    LICENSE          => 'perl', # or artistic_2 ?
    PL_FILES         => {},
    PREREQ_PM        => {'Tree::Simple' => 0}, # What version? Who knows.
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tree-Create-DepthFirst-*' },
);
