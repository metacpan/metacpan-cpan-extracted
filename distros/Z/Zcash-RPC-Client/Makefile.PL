use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Zcash::RPC::Client',
    AUTHOR           => 'Nils Knieling',
    VERSION_FROM     => 'lib/Zcash/RPC/Client.pm',
    ABSTRACT_FROM    => 'lib/Zcash/RPC/Client.pm',
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
        'Moo'               => 1.001,
        'JSON::RPC::Legacy::Client' => 1.06,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Zcash-*' },
);
