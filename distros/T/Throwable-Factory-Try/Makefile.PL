use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Throwable::Factory::Try',
    AUTHOR           => q{Lucien Coffe <lcoffe@cpan.org>},
    VERSION_FROM     => 'lib/Throwable/Factory/Try.pm',
    ABSTRACT_FROM    => 'lib/Throwable/Factory/Try.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Sub::Import'				=> 1.001,
        'Try::Tiny'					=> 0.22,
        'Throwable::Factory'		=> 0.006,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Throwable-Factory-Try-*' },
);
