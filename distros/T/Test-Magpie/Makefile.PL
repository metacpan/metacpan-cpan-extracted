
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Mocking framework with method stubs and behaviour verification\r",
  "AUTHOR" => "Oliver Charles <oliver.g.charles\@googlemail.com>, Steven Lee <stevenwh.lee\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-Magpie",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::Magpie",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Devel::PartialDump" => 0,
    "Exporter" => 0,
    "List::Util" => 0,
    "Moose" => 0,
    "Moose::Meta::Class" => 0,
    "Moose::Role" => 0,
    "Moose::Util" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Structured" => 0,
    "Scalar::Util" => 0,
    "Set::Object" => 0,
    "Test::Builder" => 0,
    "UNIVERSAL::ref" => 0,
    "aliased" => 0,
    "experimental" => 0,
    "namespace::autoclean" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Builder::Tester" => 0,
    "Test::Fatal" => 0,
    "Test::Moose" => 0,
    "Test::More" => 0,
    "Throwable" => 0,
    "constant" => 0
  },
  "VERSION" => "0.11",
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



