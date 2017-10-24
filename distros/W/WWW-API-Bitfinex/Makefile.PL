use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::API::Bitfinex',
    AUTHOR           => q{Harun Delgado <hdp@nurmol.com>},
    VERSION_FROM     => 'lib/WWW/API/Bitfinex.pm',
    ABSTRACT_FROM    => 'lib/WWW/API/Bitfinex.pm',
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
	'Mojo::UserAgent' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-API-Bitfinex-*' },
);
