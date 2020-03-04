use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile 0.06;

WriteMakefile(
  NAME           => 'Win32::TestServerManager',
  AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM   => 'lib/Win32/TestServerManager.pm',
  ABSTRACT_FROM  => 'lib/Win32/TestServerManager.pm',
  LICENSE        => 'perl',
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/Win32-TestServerManager',
    },
  },
);
