use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::Ooyala',
    AUTHOR           => q{Tim Vroom <vroom@blockstackers.com>},
    VERSION_FROM     => 'lib/WebService/Ooyala.pm',
    ABSTRACT_FROM    => 'lib/WebService/Ooyala.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'              => 0,
        'Digest::SHA'       => 0,
        'LWP::UserAgent'    => 0,
        'JSON'              => 0,
        'URI::Escape'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-Ooyala-*' },
);
