
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Module to interface with the http://PagerDuty.com service",
  "AUTHOR" => "Oleg Kostyuk <cub\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-PagerDuty",
  "EXE_FILES" => [],
  "LICENSE" => "bsd",
  "NAME" => "WebService::PagerDuty",
  "PREREQ_PM" => {
    "Class::Accessor" => 0,
    "Error" => 0,
    "HTTP::Request" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "URI" => 0,
    "URI::QueryParam" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::LWP::UserAgent" => 0,
    "Test::More" => 0,
    "Test::Most" => 0
  },
  "VERSION" => "1.20131219.1627",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::Accessor" => 0,
  "Error" => 0,
  "File::Spec" => 0,
  "HTTP::Request" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "JSON" => 0,
  "LWP::UserAgent" => 0,
  "Test::LWP::UserAgent" => 0,
  "Test::More" => 0,
  "Test::Most" => 0,
  "URI" => 0,
  "URI::QueryParam" => 0,
  "base" => 0,
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



