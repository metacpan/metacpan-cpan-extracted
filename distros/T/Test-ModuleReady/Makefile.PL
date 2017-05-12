use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::ModuleReady',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Test/ModuleReady.pm',
    ABSTRACT_FROM       => 'lib/Test/ModuleReady.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp'              => '1.08',
        'Pod::Checker'      => '1.45',
        'Test::More'        => '0.94',
        'Test::Spelling'    => '0.11',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-ModuleReady-*' },
);
