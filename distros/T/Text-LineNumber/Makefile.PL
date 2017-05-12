use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::LineNumber',
    AUTHOR              => 'Juergen Weigert <jw@suse.de>',
    VERSION_FROM        => 'LineNumber.pm',
    ABSTRACT_FROM       => 'LineNumber.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => ['Text-LineNumber-*', '*.orig'] },
);
