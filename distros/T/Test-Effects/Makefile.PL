use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.014;

WriteMakefile(
    NAME                => 'Test::Effects',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Test/Effects.pm',
    ABSTRACT_FROM       => 'lib/Test/Effects.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Trap' => 0.002001,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Effects-*' },
);
