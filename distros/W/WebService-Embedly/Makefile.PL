
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl interface to the Embedly API",
  "AUTHOR" => "Jason Wieland <jwieland\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-Embedly",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WebService::Embedly",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Response" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "Ouch" => 0,
    "Regexp::Common" => 0,
    "Test::Mock::LWP::Dispatch" => 0,
    "Test::More" => "0.88",
    "URI::Escape" => 0,
    "parent" => 0
  },
  "VERSION" => "0.10",
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



