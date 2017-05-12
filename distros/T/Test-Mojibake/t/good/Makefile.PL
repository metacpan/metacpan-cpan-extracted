
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "check your source for encoding misbehavior.",
  "AUTHOR" => "Stanislaw Pusep <stas\@sysd.org>",
  "BUILD_REQUIRES" => {
    "Encode" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::Builder::Tester" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-Mojibake",
  "EXE_FILES" => [
    "bin/scan_mojibake"
  ],
  "LICENSE" => "perl",
  "NAME" => "Test::Mojibake",
  "PREREQ_PM" => {
    "File::Spec::Functions" => 0,
    "Pod::Usage" => 0,
    "Test::Builder" => 0,
    "bytes" => 0,
    "integer" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.8",
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



