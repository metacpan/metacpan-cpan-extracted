use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'URI::ParseSearchString',
    AUTHOR              => 'Spiros Denaxas <spiros@lokku.com>',
    VERSION_FROM        => 'lib/URI/ParseSearchString.pm',
    ABSTRACT_FROM       => 'lib/URI/ParseSearchString.pm',
    PL_FILES            => {},
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
        'URI'              => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'URI-ParseSearchString-*' },
);
