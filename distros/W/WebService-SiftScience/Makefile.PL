
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.030.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;



my %WriteMakefileArgs = (
  "ABSTRACT" => "SiftScience API Bindings",
  "AUTHOR" => "Ali Anari <ali\@anari.me>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "WebService-SiftScience",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "WebService::SiftScience",
  "PREREQ_PM" => {
    "Method::Signatures" => 0,
    "Moo" => "1.006000",
    "WebService::BaseClientRole" => "0.0004",
    "WebService::Client" => 0
  },
  "TEST_REQUIRES" => {
    "DateTime" => 0,
    "Exporter" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Memoize" => 0,
    "Test::Modern" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0100",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "DateTime" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Memoize" => 0,
  "Method::Signatures" => 0,
  "Moo" => "1.006000",
  "Test::Modern" => 0,
  "Test::More" => 0,
  "WebService::BaseClientRole" => "0.0004",
  "WebService::Client" => 0,
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



