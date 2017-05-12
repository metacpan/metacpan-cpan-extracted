
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Accessing DNSMadeEasy API",
  "AUTHOR" => "Torsten Raudssus <torsten\@raudssus.de>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.96"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WWW-DNSMadeEasy",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WWW::DNSMadeEasy",
  "PREREQ_PM" => {
    "DateTime" => 0,
    "DateTime::Format::HTTP" => "0.40",
    "Digest::HMAC" => "1.03",
    "JSON" => "2.50",
    "LWP" => 0,
    "Moo" => "0.009013",
    "URI" => "1.58"
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



