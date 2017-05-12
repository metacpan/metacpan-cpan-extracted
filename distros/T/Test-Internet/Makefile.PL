#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Test::Internet',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Test/Internet.pm',
    ABSTRACT_FROM      => 'lib/Test/Internet.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Net::DNS'      => '0.82',
        'Test::Builder' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-Internet-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => { 'Test::Internet' => { file => 'lib/Test/Internet.pm', version => '0.06' } },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Test-Internet.git',
                web  => 'https://github.com/manwar/Test-Internet',
            },
        }})
     : ()
    ),
);
