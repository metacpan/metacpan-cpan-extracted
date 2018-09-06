use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::MIAB',
    AUTHOR           => q{Alexander Schneider <alexander.schneider@minati.de>},
    VERSION_FROM     => 'lib/WebService/MIAB.pm',
    ABSTRACT_FROM    => 'lib/WebService/MIAB.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'LWP::UserAgent' => '6.31',
        'MIME::Base64' => '3.13',
        re => '0.34',
        Carp => '1.38',
        JSON => '2.97001',
        Moo => '2.2010',
        'WebService::Client' => '0.0601',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-MIAB-*' },
);
