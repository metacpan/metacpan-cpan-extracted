use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'YAGL',
    AUTHOR              => 'Rich Loveland <r@rmloveland.com>',
    VERSION_FROM        => 'lib/YAGL.pm',
    ABSTRACT_FROM       => 'lib/YAGL.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'YAGL-*' },
);
