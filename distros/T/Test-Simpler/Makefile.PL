use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Simpler',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Test/Simpler.pm',
    ABSTRACT_FROM       => 'lib/Test/Simpler.pm',
    PL_FILES            => {},
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More'            => 0,
        'Test::Builder::Module' => 0,
        'PadWalker'             => 0,
        'Data::Dump'            => 0,
        'PPI'                   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Simpler-*' },
);
