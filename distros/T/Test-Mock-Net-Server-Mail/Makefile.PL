# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "mock SMTP server for use in tests",
  "AUTHOR" => "Markus Benning <ich\@markusbenning.de>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Test-Mock-Net-Server-Mail",
  "LICENSE" => "perl",
  "NAME" => "Test::Mock::Net::Server::Mail",
  "PREREQ_PM" => {
    "File::Temp" => 0,
    "IO::File" => 0,
    "IO::Socket::INET" => 0,
    "JSON" => 0,
    "Moose" => 0,
    "Net::Server::Mail::ESMTP" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "TEST_REQUIRES" => {
    "File::Find" => 0,
    "Test::SMTP" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.02",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Find" => 0,
  "File::Temp" => 0,
  "IO::File" => 0,
  "IO::Socket::INET" => 0,
  "JSON" => 0,
  "Moose" => 0,
  "Net::Server::Mail::ESMTP" => 0,
  "Test::Exception" => 0,
  "Test::More" => 0,
  "Test::SMTP" => 0,
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
