use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'lib::findbin',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/lib/findbin.pm',
    ABSTRACT_FROM       => 'lib/lib/findbin.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0, # for testing, I know I know: Test::XT
        'FindBin'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'lib-findbin-*' },
);
