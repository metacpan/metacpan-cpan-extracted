
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Client for the Pocket api (http://getpocket.com/api/)",
  "AUTHOR" => "William Wolf <throughnothing\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-Pocket",
  "EXE_FILES" => [
    "bin/pocket"
  ],
  "LICENSE" => "unrestricted",
  "NAME" => "WebService::Pocket",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "DateTime" => 0,
    "HTTP::Tiny" => "0.014",
    "JSON" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Getopt" => "0.48",
    "MooseX::SimpleConfig" => 0,
    "Net::SSLeay" => "1.49",
    "Try::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dumper" => 0,
  "DateTime" => 0,
  "File::Spec" => 0,
  "HTTP::Tiny" => "0.014",
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "JSON" => 0,
  "Moose" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "MooseX::Getopt" => "0.48",
  "MooseX::SimpleConfig" => 0,
  "Net::SSLeay" => "1.49",
  "Test::More" => 0,
  "Try::Tiny" => 0,
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



