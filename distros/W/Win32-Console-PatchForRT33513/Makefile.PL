use warnings;
use strict;
use ExtUtils::MakeMaker;


die "OS unsupported\n" if $^O ne 'MSWin32';


WriteMakefile(
    PL_FILES         => {},
    LICENSE          => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => "https://github.com/kuerbis/Win32-Console-PatchForRT33513/issues",
            },
            repository => {
              type => 'git',
              web  => 'https://github.com/kuerbis/Win32-Console-PatchForRT33513',
              url  => 'https://github.com/kuerbis/Win32-Console-PatchForRT33513.git',
            },
        },
    },
    AUTHOR           => 'Matthaeus Kiem <cuer2s@gmail.com>',
    NAME             => 'Win32::Console::PatchForRT33513',
    ABSTRACT_FROM    => 'lib/Win32/Console/PatchForRT33513.pm',
    VERSION_FROM     => 'lib/Win32/Console/PatchForRT33513.pm',
    EXE_FILES        => [],
    BUILD_REQUIRES   => {
        'Test::More'    => 0,
    },
    PREREQ_PM => {
        'strict'         => 0,
        'warnings'       => 0,
        'Win32::Console' => 0,
    },
    dist  => {
        COMPRESS => 'gzip',
        SUFFIX   => '.gz',
        TARFLAGS => '--format=gnu -cvf',
    },
    clean => {
        FILES => 'Win32-Console-PatchForRT33513-*',
    },
);
