use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Unique',
    AUTHOR              => 'Christian Werner Sr <saltbreez@cpan.org>',
    VERSION_FROM        => 'lib/Unique.pm',
    ABSTRACT_FROM       => 'lib/Unique.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Digest::MD5' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Unique-*' },
);
