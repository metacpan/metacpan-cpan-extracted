use strict;
use warnings;
use ExtUtils::MakeMaker;

link("lib/Text/Migemo.xs", "Migemo.xs");
WriteMakefile(
    NAME                => 'Text::Migemo',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM        => 'lib/Text/Migemo.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0.32,
    },
    LIBS                => '-L/usr/local/lib -lmigemo',
    CCFLAGS             => '-Isrc',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Migemo-*' },
);
