# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Lazily install missing Perl modules",
  "AUTHOR" => "Olaf Alders <olaf\@wundercounter.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "lazy",
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "lazy",
  "PREREQ_PM" => {
    "App::cpm" => "0.997017",
    "App::cpm::CLI" => 0,
    "Capture::Tiny" => 0,
    "Carp" => 0,
    "Getopt::Long" => 0,
    "Sub::Identify" => 0,
    "Sub::Name" => 0,
    "Try::Tiny" => 0,
    "feature" => 0,
    "local::lib" => "2.000024",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "LWP" => "6.35",
    "Path::Iterator::Rule" => 0,
    "Path::Tiny" => 0,
    "Test::More" => 0,
    "Test::RequiresInternet" => 0
  },
  "VERSION" => "1.000000",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::cpm" => "0.997017",
  "App::cpm::CLI" => 0,
  "Capture::Tiny" => 0,
  "Carp" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Getopt::Long" => 0,
  "LWP" => "6.35",
  "Path::Iterator::Rule" => 0,
  "Path::Tiny" => 0,
  "Sub::Identify" => 0,
  "Sub::Name" => 0,
  "Test::More" => 0,
  "Test::RequiresInternet" => 0,
  "Try::Tiny" => 0,
  "feature" => 0,
  "local::lib" => "2.000024",
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
