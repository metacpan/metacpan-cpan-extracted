# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.030.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Test Sah::Schema::* modules in distribution",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Test-Sah-Schema",
  "EXE_FILES" => [
    "script/test-sah-schema-modules"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Test::Sah::Schema",
  "PREREQ_PM" => {
    "Data::Dmp" => "0.242",
    "Data::Dump" => 0,
    "Data::Sah" => "0.914",
    "Data::Sah::Normalize" => "0.051",
    "File::Spec" => 0,
    "Getopt::Long" => "2.50",
    "Log::ger" => "0.038",
    "Log::ger::App" => "0.024",
    "Test::Builder" => 0,
    "Test::More" => "0.98",
    "Text::Diff" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.98"
  },
  "VERSION" => "0.016",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dmp" => "0.242",
  "Data::Dump" => 0,
  "Data::Sah" => "0.914",
  "Data::Sah::Normalize" => "0.051",
  "File::Spec" => 0,
  "Getopt::Long" => "2.50",
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Log::ger" => "0.038",
  "Log::ger::App" => "0.024",
  "Test::Builder" => 0,
  "Test::More" => "0.98",
  "Text::Diff" => 0,
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
