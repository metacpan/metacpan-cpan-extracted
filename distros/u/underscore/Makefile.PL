use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'underscore',
    AUTHOR              => 'Dan Kogai <dankogai@dan.co.jp>',
    VERSION_FROM        => 'lib/underscore.pm',
    ABSTRACT_FROM       => 'lib/underscore.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'underscore-*' },
);
