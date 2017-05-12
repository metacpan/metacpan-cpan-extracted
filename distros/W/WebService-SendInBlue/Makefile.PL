
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl API for https://www.sendinblue.com/ REST API ",
  "AUTHOR" => "Bruno Tavares <eu\@brunotavares.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-SendInBlue",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WebService::SendInBlue",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "HTTP::Request" => 0,
    "IO::Socket::INET" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "URI::Query" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dumper" => 0,
  "HTTP::Request" => 0,
  "IO::Socket::INET" => 0,
  "JSON" => 0,
  "LWP::UserAgent" => 0,
  "Test::Exception" => 0,
  "Test::More" => 0,
  "URI::Query" => 0,
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



