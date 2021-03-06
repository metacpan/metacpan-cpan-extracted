# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "let's have a nice and human readable dump of our objects!",
  "AUTHOR" => "Gianni Ceccarelli <gianni.ceccarelli\@broadbean.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Test-NiceDump",
  "LICENSE" => "perl",
  "NAME" => "Test::NiceDump",
  "PREREQ_PM" => {
    "Data::Dump" => 0,
    "Data::Dump::Filtered" => 0,
    "Exporter" => 0,
    "Safe::Isa" => "1.000010",
    "Test::Builder" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "1.0.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dump" => 0,
  "Data::Dump::Filtered" => 0,
  "Exporter" => 0,
  "Safe::Isa" => "1.000010",
  "Test::Builder" => 0,
  "Test::More" => 0,
  "overload" => 0,
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
