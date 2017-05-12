
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Process (and optionally store) karma points",
  "AUTHOR" => "Hinrik \303\226rn Sigur\303\260sson <hinrik.sig\@gmail.com>, Apocalypse <APOCAL\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.47"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Text-Karma",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Text::Karma",
  "PREREQ_PM" => {
    "Any::Moose" => "0.15",
    "Moose" => "2.0007",
    "MooseX::StrictConstructor" => "0.16",
    "Mouse" => "0.93",
    "MouseX::StrictConstructor" => "0.02",
    "namespace::clean" => "0.20"
  },
  "VERSION" => "0.05",
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



