use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Win32::IE::SlideShow',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Win32/IE/SlideShow.pm',
  ABSTRACT_FROM => 'lib/Win32/IE/SlideShow.pm',
  PREREQ_PM => {
    'Test::Exception'     => 0,
    'Test::More'          => '0.47',
    'Test::UseAllModules' => '0.09',
    'Win32::API'          => 0,
    'Win32::OLE'          => 0,
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);
