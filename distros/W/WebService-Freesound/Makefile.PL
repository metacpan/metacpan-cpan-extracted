use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::Freesound',
    AUTHOR           => q{Andy Cragg <andyc@caesuramedia.com>},
    VERSION_FROM     => 'lib/WebService/Freesound.pm',
    ABSTRACT_FROM    => 'lib/WebService/Freesound.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'LWP::UserAgent' => 0,
        'Test::MockModule' => 0,
        'HTTP::Response' => 0,
        'JSON' => 0,

    },
    PREREQ_PM => {
        'LWP::Simple' => 0,
        'LWP::UserAgent' => 0,
        'Data::Dumper' => 0,
        'JSON' => 0,
        'Carp' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-Freesound-*' },
);
