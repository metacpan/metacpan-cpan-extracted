require 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::MockCommand',
    AUTHOR              => 'Stuart Caie <kyzer@4u.net>',
    VERSION_FROM        => 'lib/Test/MockCommand.pm',
    ABSTRACT_FROM       => 'lib/Test/MockCommand.pm',
    PREREQ_PM => {
      Carp              => 0,
      Data::Dumper      => 0,
      Errno             => 0,
      POSIX             => 0,
      Symbol            => 0,
      Tie::Handle       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
