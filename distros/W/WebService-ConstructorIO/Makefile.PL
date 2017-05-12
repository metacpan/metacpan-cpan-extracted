use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::ConstructorIO',
    AUTHOR           => q{Dan McCormick <dan@constructor.io>},
    VERSION_FROM     => 'lib/WebService/ConstructorIO.pm',
    ABSTRACT_FROM    => 'lib/WebService/ConstructorIO.pm',
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
        'Method::Signatures' => 0,
        'Moo' => '1.006000',
        'WebService::Client' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-ConstructorIO-*' },
);
