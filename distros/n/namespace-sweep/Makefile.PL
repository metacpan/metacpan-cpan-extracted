
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Sweep up imported subs in your classes",
  "AUTHOR" => "Mike Friedman <friedo\@friedo.com>",
  "BUILD_REQUIRES" => {
    "Sub::Name" => 0,
    "Test::More" => 0,
    "overload" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "namespace-sweep",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "namespace::sweep",
  "PREREQ_PM" => {
    "B::Hooks::EndOfScope" => "0.09",
    "Carp" => 0,
    "Data::Dumper" => 0,
    "List::Util" => 0,
    "Package::Stash" => "0.33",
    "Scalar::Util" => 0,
    "Sub::Identify" => "0.04",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.006",
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



