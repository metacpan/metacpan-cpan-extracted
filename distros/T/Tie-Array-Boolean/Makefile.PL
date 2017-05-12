use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Array::Boolean',
    AUTHOR              => 'Kyle Hasselbacher <kyleha@gmail.com>',
    VERSION_FROM        => 'lib/Tie/Array/Boolean.pm',
    ABSTRACT_FROM       => 'lib/Tie/Array/Boolean.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Tie::Array' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-Array-Boolean-*' },
);
