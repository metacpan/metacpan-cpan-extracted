
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl module to access Amazon's Glacier service.",
  "AUTHOR" => "Charles A. Wimmer <charles\@wimmer.net>",
  "BUILD_REQUIRES" => {
    "Pod::Coverage::TrustPod" => 0,
    "TAP::Formatter::JUnit" => 0,
    "TAP::Harness::JUnit" => 0,
    "Test::Perl::Critic" => 0,
    "Test::Pod" => 0,
    "Test::Pod::Coverage" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-Amazon-Glacier",
  "EXE_FILES" => [
    "bin/glacier"
  ],
  "LICENSE" => "bsd",
  "NAME" => "WebService::Amazon::Glacier",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Digest::SHA" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Request" => 0,
    "JSON" => 0,
    "LWP::Protocol::https" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "MooseX::App" => 0,
    "MooseX::App::Command" => 0,
    "Net::Amazon::SignatureVersion4" => 0,
    "POSIX" => 0,
    "TryCatch" => 0,
    "URI::Encode" => 0,
    "YAML::XS" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001",
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



