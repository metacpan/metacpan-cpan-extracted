use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::SuperMan',
    AUTHOR           => q{MC Cheung <mc.cheung@aol.com>},
    VERSION_FROM     => 'lib/WWW/SuperMan.pm',
    ABSTRACT_FROM    => 'lib/WWW/SuperMan.pm',
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
        Slurp => 0,
        JSON => 0,
        'LWP::UserAgent' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-SuperMan-*' },
);
