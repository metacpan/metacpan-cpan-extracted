use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::EasyTemplate',
    AUTHOR              => 'Luis Chavez <lchavez@andrew.cmu.edu>',
    VERSION_FROM        => 'lib/Text/EasyTemplate.pm',
    ABSTRACT_FROM       => 'lib/Text/EasyTemplate.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-EasyTemplate-*' },
);
