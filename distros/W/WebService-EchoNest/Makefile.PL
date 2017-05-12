
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A simple interface to the EchoNest API",
  "AUTHOR" => "Nick Langridge <nickl\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::LWP::UserAgent" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-EchoNest",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WebService::EchoNest",
  "PREREQ_PM" => {
    "JSON::XS::VersionOneAndTwo" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "MooseX::StrictConstructor" => 0,
    "URI::QueryParam" => 0
  },
  "VERSION" => "0.007",
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



