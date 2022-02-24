
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;

# Git.io has retired their service, so this module shouldn't be installable.
# It exists to inform it's current users, rather than just disappear.
die "OS unsupported\n";



my %WriteMakefileArgs = (
  "ABSTRACT" => "Shorten GitHub URLs using GitHub's URL shortener - git.io",
  "AUTHOR" => "James Aitken <jaitken\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WWW-Shorten-GitHub",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WWW::Shorten::GitHub",
  "PREREQ_PM" => {
    "Carp" => "1.11",
    "Exporter" => "5.65",
    "URI" => "1.38",
    "LWP::Protocol::https" => "0",
    "WWW::Shorten::generic" => "1.92",
    "base" => "2.14"
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88",
    "WWW::Shorten" => "1.98"
  },
  "VERSION" => "0.1.8",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



