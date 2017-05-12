use strict;
use ExtUtils::MakeMaker;

my %args = (
  NAME           => 'Win32::TestServerManager',
  AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM   => 'lib/Win32/TestServerManager.pm',
  ABSTRACT_FROM  => 'lib/Win32/TestServerManager.pm',
  PREREQ_PM => {
    'B::Deparse'           => 0,
    'File::Slurp'          => 0,
    'File::Spec'           => 0,
    'File::Temp'           => 0,
    'Test::UseAllModules'  => 0,
    'Win32'                => 0,
    'Win32::Process'       => 0,
  },
);
$args{LICENSE} = 'perl' if $ExtUtils::MakeMaker::VERSION >= 6.31;

WriteMakefile( %args );
