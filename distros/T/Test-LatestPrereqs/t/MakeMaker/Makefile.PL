use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME      => 'Foo::Bar',
  PREREQ_PM => {
    'File::Spec'          => 0,
    'Test::More'          => '0.47',
    'Test::UseAllModules' => '0.10',
  },
);
