
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Declarative 0MQ Infrastructure",
  "AUTHOR" => "Steffen Mueller <smueller\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "ZMQ-Declare",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "ZMQ::Declare",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Clone" => 0,
    "Data::Dumper" => 0,
    "Data::Rx" => 0,
    "File::Spec" => 0,
    "JSON" => 0,
    "Moose" => 0,
    "Scalar::Util" => 0,
    "Storable" => 0,
    "Test::More" => "0.88",
    "ZeroMQ" => 0,
    "autodie" => 0,
    "lib" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Clone" => 0,
  "Data::Dumper" => 0,
  "Data::Rx" => 0,
  "File::Spec" => 0,
  "JSON" => 0,
  "Moose" => 0,
  "Scalar::Util" => 0,
  "Storable" => 0,
  "Test::More" => "0.88",
  "ZeroMQ" => 0,
  "autodie" => 0,
  "lib" => 0,
  "parent" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



