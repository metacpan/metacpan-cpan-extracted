use ExtUtils::MakeMaker;

die "Win32::MediaPlayer can only be installed on MS Win32 Platforms\n Makefile not written\n\n" unless $^O eq 'MSWin32';

WriteMakefile(
    NAME         => 'Win32::MediaPlayer',
    VERSION_FROM => 'lib/Win32/MediaPlayer.pm', # finds $VERSION
    AUTHOR       => 'LiloHuang',
    ABSTRACT_FROM=> 'lib/Win32/MediaPlayer.pm',
    PREREQ_PM    => {   'Win32::API'            => 0}
);