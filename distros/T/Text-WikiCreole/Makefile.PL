use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::WikiCreole',
    AUTHOR              => 'Jason Burnett <jason@jnj.org>',
    VERSION_FROM        => 'lib/Text/WikiCreole.pm',
    ABSTRACT_FROM       => 'lib/Text/WikiCreole.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-WikiCreole-*' },
);
