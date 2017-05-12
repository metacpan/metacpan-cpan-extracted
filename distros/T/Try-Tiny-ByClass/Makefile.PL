use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Try::Tiny::ByClass',
    AUTHOR              => q{Lukas Mai <l.mai@web.de>},
    VERSION_FROM        => 'lib/Try/Tiny/ByClass.pm',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.56',
    },
    LICENSE => 'perl',
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'IO::Handle' => 0,
    },
    PREREQ_PM => {
        'warnings' => 0,
        'strict' => 0,
        'base' => 0,
        'Exporter' => 0,
        'Try::Tiny' => 0,
        'Dispatch::Class' => 0,
    },
    MIN_PERL_VERSION => '5.6.0',
    META_MERGE => {
        resources => {
            repository => {
                url => 'git://github.com/mauke/Try-Tiny-ByClass.git',
                web => 'https://github.com/mauke/Try-Tiny-ByClass',
                type => 'git',
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Try-Tiny-ByClass-*' },
);
