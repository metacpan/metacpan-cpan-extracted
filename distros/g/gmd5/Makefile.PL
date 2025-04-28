use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'gmd5',
    VERSION_FROM      => 'lib/gmd5.pm',
    ABSTRACT          => 'Pure Perl MD5 implementation for Perl 5.8+',
    AUTHOR            => 'OnEhIppY, Domero Software <domerosoftware@gmail.com>',
    LICENSE           => 'perl_5',
    PREREQ_PM         => {
        'strict'      => 0,
        'warnings'    => 0,
        'Exporter'    => 0,
        'Time::HiRes' => 0,
    },
    TEST_REQUIRES     => {
        'Test::More'  => '0.88',
        'Digest::MD5' => 0,
    },
    MIN_PERL_VERSION  => '5.008',
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/DomeroSoftware/gmd5.git',
                web  => 'https://github.com/DomeroSoftware/gmd5',
            },
            bugtracker => {
                web => 'https://github.com/DomeroSoftware/gmd5/issues',
            },
        },
    },
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean             => { FILES => 'gmd5-*' },
);