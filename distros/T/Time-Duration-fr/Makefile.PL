use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Time::Duration::fr',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Time/Duration/fr.pm',
    ABSTRACT_FROM       => 'lib/Time/Duration/fr.pm',
    META_MERGE          => {
        resources       => {
            repository  => 'http://github.com/maddingue/Time-Duration-fr',
        },
    },
    PL_FILES            => {},
    PREREQ_PM => {
        # prereqs
        'Exporter'          => 0,
        'Time::Duration'    => 0,

        # build/test prereqs
        'Test::More'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Time-Duration-fr-*' },
);
