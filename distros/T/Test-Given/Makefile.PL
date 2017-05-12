use 5.10.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Given',
    AUTHOR              => q{Robert Juliano <rovjuvano@gmail.com>},
    VERSION_FROM        => 'lib/Test/Given.pm',
    ABSTRACT_FROM       => 'lib/Test/Given.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'parent'     => 0,
        'version'    => 0.77,
    },
    META_MERGE => {
        bugtracker => 'https://github.com/rovjuvano/Test-Given/issues',
        homepage   => 'https://github.com/rovjuvano/Test-Given',
        repository => 'git://github.com/rovjuvano/Test-Given.git',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Given-*' },
);
