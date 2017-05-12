use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Win32::IEFavorites',
    VERSION_FROM      => 'lib/Win32/IEFavorites.pm',
    PREREQ_PM         => {
      'Win32::TieRegistry' => 0,
      'File::Find::Rule' => 0,
      'File::Spec' => 0,
      'Win32::FileTime' => 0,
      'Config::IniFiles' => 0,
      'DateTime' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Win32/IEFavorites.pm',
       AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>') : ()
    ),
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
      (LICENSE => 'perl') : ()
    ),
);
