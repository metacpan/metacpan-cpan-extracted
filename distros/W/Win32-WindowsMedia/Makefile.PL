use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Win32::WindowsMedia',
    AUTHOR              => 'Andrew S. Kennedy <shamrock@cpan.org>',
    VERSION_FROM        => 'lib/Win32/WindowsMedia.pm',
    ABSTRACT_FROM       => 'lib/Win32/WindowsMedia.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Win32::OLE' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Win32-WindowsMedia-*' },
);
