use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'Win32::UrlCache',
  AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM   => 'lib/Win32/UrlCache.pm',
  ABSTRACT_FROM  => 'lib/Win32/UrlCache.pm',
  PREREQ_PM => {
    'Class::Accessor::Fast' => 0,
    'Test::UseAllModules'   => 0,
    'DateTime'              => 0,
    'Math::BigInt'          => 1.78,
    ( $^O eq 'MSWin32'
      ? (
          'Win32::API'         => 0,
          'Win32::TieRegistry' => 0,
        )
      : ()
    ),
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? (LICENSE => 'perl')
    : ()
  ),
);
