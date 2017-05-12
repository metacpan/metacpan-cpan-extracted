
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl interface to y.ahoo.it",
  "AUTHOR" => "Charles A. Wimmer <charles\@wimmer.net>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Pod::Coverage::TrustPod" => 0,
    "TAP::Formatter::JUnit" => 0,
    "TAP::Harness::JUnit" => 0,
    "Test::More" => 0,
    "Test::Perl::Critic" => 0,
    "Test::Pod::Coverage" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WWW-Shorten-Yahooit",
  "EXE_FILES" => [],
  "LICENSE" => "bsd",
  "NAME" => "WWW::Shorten::Yahooit",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "WWW::Shorten::generic" => 0,
    "WWW::YQL" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
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



