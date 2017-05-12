use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Harness::FileFilter',
    AUTHOR              => 'Claes Jacobsson <claesjac@cpan.org>',
    VERSION_FROM        => 'lib/Test/Harness/FileFilter.pm',
    ABSTRACT_FROM       => 'lib/Test/Harness/FileFilter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'File::Spec'    => 0,
        'Test::Harness' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Harness-FileFilter-*' },
);
