use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Win32::HostExplorer',
    AUTHOR              => 'George Kevin Hathorn <gekeha@gmail.com>',
    VERSION_FROM        => 'lib/Win32/HostExplorer.pm',
    ABSTRACT_FROM       => 'lib/Win32/HostExplorer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Win32-HostExplorer-*' },
);
