use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'gb64',
    VERSION_FROM      => 'lib/gb64.pm',
    ABSTRACT          => 'Fast Pure Perl Base64 Encoding and Decoding',
    AUTHOR            => 'OnEhIppY, Domero Software <domerosoftware@gmail.com>',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.008',
    PREREQ_PM         => {
        'strict'      => 0,
        'warnings'    => 0,
        'Exporter'    => 0,
    },
    TEST_REQUIRES     => {
        'Test::More'  => '0.88',
        'MIME::Base64' => 0,  # Voor testvergelijkingen
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',  # Voor TEST_REQUIRES
    },
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage    => 'https://github.com/DomeroSoftware/gb64',
            repository  => {
                type => 'git',
                url  => 'https://github.com/DomeroSoftware/gb64.git',
                web  => 'https://github.com/DomeroSoftware/gb64',
            },
            bugtracker  => {
                web => 'https://github.com/DomeroSoftware/gb64/issues',
            },
        },
        keywords    => [ 'base64', 'encoding', 'decoding', 'pure perl', 'rfc 4648' ],
        no_index    => {
            directory => [ 't', 'benchmarks' ],
        },
    },
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean             => { FILES => 'gb64-*' },
);