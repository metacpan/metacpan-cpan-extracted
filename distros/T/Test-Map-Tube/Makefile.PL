#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Test::Map::Tube',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Test/Map/Tube.pm',
    ABSTRACT_FROM      => 'lib/Test/Map/Tube.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Map::Tube'     => '3.64',
        'Data::Compare' => '1.25',
        'Test::Builder' => '1.001014',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-Map-Tube-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => { 'Test::Map::Tube' => { file => 'lib/Test/Map/Tube.pm', version => '0.56' } },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Test-Map-Tube.git',
                web  => 'https://github.com/manwar/Test-Map-Tube',
            },
        }})
     : ()
    ),
);
