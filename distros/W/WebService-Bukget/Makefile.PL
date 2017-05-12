
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides access to the v3 Bukget API",
  "AUTHOR" => "Ben van Staveren <madcat\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.38",
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.38"
  },
  "DISTNAME" => "WebService-Bukget",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WebService::Bukget",
  "PREREQ_PM" => {
    "Mojo::Base" => 0,
    "Mojo::JSON" => 0,
    "Mojo::UserAgent" => 0,
    "Try::Tiny" => 0,
    "boolean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.00",
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



