use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::MCBouncer',
    AUTHOR           => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM     => 'lib/WebService/MCBouncer.pm',
    ABSTRACT_FROM    => 'lib/WebService/MCBouncer.pm',
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
        'Moo' => 0,
        'LWP::UserAgent' => 0,
        'JSON' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-MCBouncer-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/bigpresh/WebService-MCBouncer',
            bugtracker => 'https://github.com/bigpresh/WebService-MCBouncer/issues',
            homepage   => 'https://github.com/bigpresh/WebService-MCBouncer/',
        },  
    },
);
