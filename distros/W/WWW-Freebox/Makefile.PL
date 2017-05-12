use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::Freebox',
    AUTHOR           => q{Alexandre van Beurden <alexandre.vanbeurden.dev@gmail.com>},
    VERSION_FROM     => 'lib/WWW/Freebox.pm',
    ABSTRACT_FROM    => 'lib/WWW/Freebox.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP::Simple' => 6.13,
        'LWP' => 6.13,
        'HTTP::Request' => 6.00,
        'HTTP::Request::Common' => 6.04,
        'JSON' => 2.90,
        'Digest::HMAC_SHA1' => 1.03,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Freebox-*' },
);
