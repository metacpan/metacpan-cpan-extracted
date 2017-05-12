use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'lib::tiny',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/lib/tiny.pm',
    ABSTRACT_FROM       => 'lib/lib/tiny.pod',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'lib-tiny-*' },
);