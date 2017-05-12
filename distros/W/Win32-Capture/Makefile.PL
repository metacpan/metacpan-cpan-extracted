use ExtUtils::MakeMaker;

die "Win32::Capture is only compatible with MS Win32 Platforms.\n Makefile not written.\n\n" unless $^O eq 'MSWin32';

WriteMakefile(
    NAME          => 'Win32::Capture',
    VERSION_FROM  => 'lib/Win32/Capture.pm', # finds $VERSION
    AUTHOR        => 'LiloHuang <kenwu@cpan.org>',
    ABSTRACT_FROM => 'lib/Win32/Capture.pm',
    PREREQ_PM     => { 
        'Win32::API'            => 0,
        'Win32::GUI::DIBitmap'  => 0
    }
);