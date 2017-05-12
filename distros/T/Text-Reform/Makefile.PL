use 5.005;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Reform',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Text/Reform.pm',
    ABSTRACT_FROM       => 'lib/Text/Reform.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Exporter'   => 0,
        'Test::More' => 0,
        #'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Reform-*' },
);
