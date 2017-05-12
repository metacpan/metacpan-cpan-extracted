use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Test::LatestPrereqs',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Test/LatestPrereqs.pm',
  ABSTRACT_FROM => 'lib/Test/LatestPrereqs.pm',
  PREREQ_PM => {
    'Class::Inspector'    => 0,
    'CPAN::Version'       => 0,
    'File::Find::Rule'    => 0,
    'File::Spec'          => 0,
    'Test::More'          => '0.47',
    'Test::UseAllModules' => '0.11',
  },
  EXE_FILES => ['bin/test_prereqs_version'],
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);
