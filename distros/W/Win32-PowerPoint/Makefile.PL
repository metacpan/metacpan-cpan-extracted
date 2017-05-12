use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME                => 'Win32::PowerPoint',
  AUTHOR              => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM        => 'lib/Win32/PowerPoint.pm',
  ABSTRACT_FROM       => 'lib/Win32/PowerPoint.pm',
  PREREQ_PM => {
    'Exporter'            => '5.57',
    'File::Spec'          => 0,
    'Test::More'          => '0.47',
    'Test::UseAllModules' => '0.09',
    'Win32::OLE'          => 0,
    (( $^O =~ /cygwin/ && $] < 5.010 )
      ? ( 'Filesys::CygwinPaths' => 0 )
      : ()
    ),
  },
  LICENSE => 'perl',
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/win32-powerpoint',
    },
  },
);

my $eumm = eval $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}    if $eumm < 6.31;
delete $params{META_MERGE} if $eumm < 6.46;

WriteMakefile(%params);
