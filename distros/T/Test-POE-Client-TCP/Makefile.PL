
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A POE Component providing TCP client services for test cases",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.59",
    "Test::More" => "0.47",
    "Text::ParseWords" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-POE-Client-TCP",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::POE::Client::TCP",
  "PREREQ_PM" => {
    "POE" => "1.28",
    "POE::Filter" => 0,
    "POE::Filter::Line" => 0,
    "POE::Wheel::ReadWrite" => 0,
    "POE::Wheel::SocketFactory" => 0
  },
  "VERSION" => "1.12",
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



