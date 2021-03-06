
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.031.
use strict;
use warnings;



use ExtUtils::MakeMaker;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Redis storage for WWW::Session",
  "AUTHOR" => "Jeffrey Goff <jeffrey.goff\@evozon.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "WWW-Session-Storage-Redis",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WWW::Session::Storage::Redis",
  "PREREQ_PM" => {
    "Cache::Redis" => 0,
    "JSON" => 0,
    "Storable" => 0,
    "WWW::Session" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Deep" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Cache::Redis" => 0,
  "ExtUtils::MakeMaker" => 0,
  "JSON" => 0,
  "Storable" => 0,
  "Test::Deep" => 0,
  "Test::Exception" => 0,
  "Test::More" => 0,
  "WWW::Session" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



