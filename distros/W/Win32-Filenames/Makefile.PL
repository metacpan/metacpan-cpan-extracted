use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Win32::Filenames',
    AUTHOR              => 'Brent Hostetler <brent@the-hostetlers.net>',
    VERSION_FROM        => 'lib\Win32\Filenames.pm',
    ABSTRACT_FROM       => 'lib\Win32\Filenames.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Win32-Filenames-*' },
);
