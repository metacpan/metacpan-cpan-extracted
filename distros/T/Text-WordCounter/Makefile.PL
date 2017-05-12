
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "counting words in multilingual texts",
  "AUTHOR" => "Zbigniew Lukasiak <zlukasiak\@opera.com>, Tadeusz So\305\233nierz, tsosnierz\@opera.com",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Text-WordCounter",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Text::WordCounter",
  "PREREQ_PM" => {
    "Lingua::Stem" => 0,
    "Lingua::ZH::MMSEG" => 0,
    "Moose" => 0,
    "URI::Find" => 0,
    "Unicode::UCD" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
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



