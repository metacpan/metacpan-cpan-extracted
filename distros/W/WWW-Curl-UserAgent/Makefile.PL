
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "UserAgent based on libcurl",
  "AUTHOR" => "Julian Knocke, Othello Maurer",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Sub::Override" => 0,
    "Test::MockObject" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WWW-Curl-UserAgent",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WWW::Curl::UserAgent",
  "PREREQ_PM" => {
    "HTTP::Request" => 0,
    "HTTP::Response" => 0,
    "IO::Select" => 0,
    "Moose" => 0,
    "Time::HiRes" => 0,
    "WWW::Curl::Easy" => 0,
    "WWW::Curl::Multi" => 0,
    "bytes" => 0
  },
  "VERSION" => "0.9.6",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



