use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Hash::ReadonlyStack',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/Tie/Hash/ReadonlyStack.pm',
    ABSTRACT_FROM       => 'lib/Tie/Hash/ReadonlyStack.pod',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-Hash-ReadonlyStack-*' },
);
