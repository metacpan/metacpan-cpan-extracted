use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'URI::crid',
    AUTHOR              => 'Ali Craigmile <ali@hodgers.com>',
    VERSION_FROM        => 'lib/URI/crid.pm',
    ABSTRACT_FROM       => 'lib/URI/crid.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'URI-crid-*' },
);
