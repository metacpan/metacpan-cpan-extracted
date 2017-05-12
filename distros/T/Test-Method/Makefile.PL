
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "test sugar for methods",
  "AUTHOR" => "Caleb Cushing <xenoterracide\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-Method",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Test::Method",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "Scalar::Util" => 0,
    "Test::Builder" => 0,
    "Test::Deep::NoTest" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Deep" => 0,
    "Test::More" => "0.88",
    "Test::Tester" => 0
  },
  "VERSION" => "0.001002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Exporter" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Scalar::Util" => 0,
  "Test::Builder" => 0,
  "Test::Deep" => 0,
  "Test::Deep::NoTest" => 0,
  "Test::More" => "0.88",
  "Test::Tester" => 0,
  "parent" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



