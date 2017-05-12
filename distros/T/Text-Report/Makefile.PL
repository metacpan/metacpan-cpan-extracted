use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Report',
    VERSION             => '1.004',
    AUTHOR              => 'David Huggins <davidius@cpan.org>',
    VERSION_FROM        => 'lib/Text/Report.pm',
    ABSTRACT_FROM       => 'lib/Text/Report.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Report-*' },
);
