use strict;
use warnings;
use ExtUtils::MakeMaker;

link("lib/Text/CSV/LibCSV.xs", "LibCSV.xs");
WriteMakefile(
    NAME                => 'Text::CSV::LibCSV',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM        => 'lib/Text/CSV/LibCSV.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.32,
    },
    LIBS                => '-L/usr/lib -lcsv',
    CCFLAGS             => '-I/usr/include/libcsv -Isrc',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-CSV-LibCSV-*' },
);

