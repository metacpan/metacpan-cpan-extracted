use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'eGuideDog::Festival',
    AUTHOR              => 'Cameron Wong <hgn823-eguidedog@yahoo.com.cn>',
    VERSION_FROM        => 'lib/eGuideDog/Festival.pm',
    ABSTRACT_FROM       => 'lib/eGuideDog/Festival.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'eGuideDog-Festival-*' },
);
