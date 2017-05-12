
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "WebScraping pseudo-API for iDoneThis",
  "AUTHOR" => "Paul Fenwick <pjf\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-Idonethis",
  "EXE_FILES" => [
    "bin/idone",
    "bin/idonethis-memories"
  ],
  "LICENSE" => "perl",
  "NAME" => "WebService::Idonethis",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Config::Tiny" => 0,
    "Date::Manip::Date" => 0,
    "File::Spec" => 0,
    "File::XDG" => 0,
    "Getopt::Std" => 0,
    "HTML::Entities" => 0,
    "HTTP::Cookies" => 0,
    "HTTP::Request" => 0,
    "JSON::Any" => 0,
    "LWP::Protocol::https" => 0,
    "Moo" => 0,
    "POSIX" => 0,
    "Pod::Usage" => 0,
    "Try::Tiny" => 0,
    "WWW::Mechanize" => 0,
    "autodie" => 0,
    "constant" => 0,
    "strict" => 0,
    "utf8::all" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.23",
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



