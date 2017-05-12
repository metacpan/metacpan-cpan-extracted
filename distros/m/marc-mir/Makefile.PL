
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "DSL to manipulate MIR records.",
  "AUTHOR" => "Marc Chantreux <khatar\@phear.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "YAML" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "marc-mir",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "marc::mir",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "Modern::Perl" => 0,
    "Perlude" => 0,
    "autodie" => 0,
    "parent" => 0
  },
  "VERSION" => "0.4",
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



