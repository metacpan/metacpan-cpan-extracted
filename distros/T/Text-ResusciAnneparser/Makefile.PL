
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Parser for XML logfiles of the Resusci Anne Skills Station software",
  "AUTHOR" => "Lieven Hollevoet <hollie\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Text-ResusciAnneparser",
  "EXE_FILES" => [
    "bin/basic.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Text::ResusciAnneparser",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "DateTime" => 0,
    "Moose" => 0,
    "XML::Simple" => 0,
    "autodie" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0
  },
  "VERSION" => "0.03",
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



