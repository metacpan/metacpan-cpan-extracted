#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'URL::Check',
    AUTHOR             => q{Alexandre Masselot <alexmass@cpan.org>},
    VERSION_FROM       => 'lib/URL/Check.pm',
    ABSTRACT_FROM      => 'lib/URL/Check.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/url-check' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES      => {
        'Test::More'    => 0,
        'Capture::Tiny' => '0.28',
    },
    PREREQ_PM            => {
        'Mail::Sendmail' => 0,
        'Time::HiRes'    => 0,
        'LWP::Simple'    => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'URL-Check-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => { 'URL::Check' => { file => 'lib/URL/Check.pm', version => '0.11' } },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/URL-Check.git',
                web  => 'https://github.com/manwar/URL-Check',
            },
        }})
     : ()
    ),
);
