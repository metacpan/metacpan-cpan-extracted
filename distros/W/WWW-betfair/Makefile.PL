use 5.10.1;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::betfair',
    AUTHOR           => q{David Farrell <davidnmfarrell@gmail.com>},
    VERSION_FROM     => 'lib/WWW/betfair.pm',
    ABSTRACT_FROM    => 'lib/WWW/betfair.pm',
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
        'Time::Piece'       => 1.20,
        'LWP::UserAgent'    => 6.05,
        'HTTP::Request'     => 6.00,
        'XML::Simple'       => 2.20,
        'Carp'              => 1.26,
        'Crypt::CBC'        => 2.32,
        'Crypt::Blowfish'   => 2.12,
        'Regexp::Common'    => 2013031301,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-betfair-*' },
);
