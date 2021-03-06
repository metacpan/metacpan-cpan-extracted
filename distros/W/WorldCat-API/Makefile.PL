# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.011.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Moo bindings for the OCLC WorldCat API",
  "AUTHOR" => "Daniel Schmidt <danschmidt5189\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "WorldCat-API",
  "EXE_FILES" => [
    "bin/find-by-oclc-number"
  ],
  "LICENSE" => "perl",
  "NAME" => "WorldCat::API",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Digest::SHA" => 0,
    "HTTP::Request" => 0,
    "HTTP::Status" => 0,
    "LWP::UserAgent" => 0,
    "MARC::Record" => 0,
    "Math::Random::Secure" => 0,
    "Moo" => 0,
    "Readonly" => 0,
    "Time::Piece" => 0,
    "XML::Simple" => 0,
    "feature" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "lib" => 0,
    "local::lib" => 0
  },
  "VERSION" => "1.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "Digest::SHA" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "HTTP::Request" => 0,
  "HTTP::Status" => 0,
  "LWP::UserAgent" => 0,
  "MARC::Record" => 0,
  "Math::Random::Secure" => 0,
  "Moo" => 0,
  "Readonly" => 0,
  "Test::Deep" => 0,
  "Test::Fatal" => 0,
  "Test::More" => 0,
  "Time::Piece" => 0,
  "XML::Simple" => 0,
  "feature" => 0,
  "lib" => 0,
  "local::lib" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
