use strict;
BEGIN {
    eval {
        require warnings;
        warnings->import;
        1;
    }
    or do {
        $^W = 1;
    };
} # for non-warnings perls, from J ben Jore.
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Constrained',
    AUTHOR              => 'Zaxo <zaxo@cpan.org>',
    VERSION_FROM        => 'lib/Tie/Constrained.pm',
    ABSTRACT_FROM       => 'lib/Tie/Constrained.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Simple' => 0,
        'Errno' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-Constrained-*' },
);

