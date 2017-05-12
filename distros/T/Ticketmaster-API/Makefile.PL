use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Ticketmaster::API',
    AUTHOR           => q{Erik Tank <erik.tank@ticketmaster.com>},
    VERSION_FROM     => 'lib/Ticketmaster/API.pm',
    ABSTRACT_FROM    => 'lib/Ticketmaster/API.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'         => 0,
        'Test::Mock::Simple' => 0.09,
    },
    PREREQ_PM => {
        'Carp'               => 1.0,
        'JSON::XS'           => 3.0,
        'LWP::UserAgent'     => 6.0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Ticketmaster-API-*' },
);
