use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Hash::Method',
    AUTHOR              => 'Yves Orton <yves@cpan.org>',
    VERSION_FROM        => 'lib/Tie/Hash/Method.pm',
    ABSTRACT_FROM       => 'lib/Tie/Hash/Method.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-Hash-Method-*' },
);
