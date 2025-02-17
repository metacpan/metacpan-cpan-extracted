# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.037.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "XML parser/representation for ClinicalTrials.gov data",
  "AUTHOR" => "chromatic",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "XML-Parser-ClinicalTrials-Study",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "XML::Parser::ClinicalTrials::Study",
  "PREREQ_PM" => {
    "DateTime::Format::Natural" => 0,
    "XML::Rabbit" => 0,
    "XML::Rabbit::Root" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Slurper" => 0,
    "Test::Most" => 0
  },
  "VERSION" => "1.20150818",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "DateTime::Format::Natural" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Slurper" => 0,
  "Test::Most" => 0,
  "XML::Rabbit" => 0,
  "XML::Rabbit::Root" => 0,
  "constant" => 0,
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
