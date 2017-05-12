use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::DxHash',
    AUTHOR              => 'Kevin Ruscoe <kevin@sapphireoflondon.org>',
    VERSION_FROM        => 'lib/Tie/DxHash.pm',
    ABSTRACT_FROM       => 'lib/Tie/DxHash.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-DxHash-*' },
);
