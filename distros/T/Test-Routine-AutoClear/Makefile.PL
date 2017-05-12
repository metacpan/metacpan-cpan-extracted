
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Enables autoclearing attrs in Test::Routines",
  "AUTHOR" => "Piers Cawley <pdcawley\@bofh.org.uk>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "Test::Routine::Util" => 0,
    "namespace::autoclean" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-Routine-AutoClear",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::Routine::AutoClear",
  "PREREQ_PM" => {
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "Test::Routine" => 0
  },
  "VERSION" => "0.004",
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



