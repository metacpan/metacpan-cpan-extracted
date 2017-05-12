
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Automagically dispatches subs to XML::Parser::Expat handlers",
  "AUTHOR" => "Patrick Seebauer <patpatpat\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "XML-Parser-Expat-Dispatched",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "XML::Parser::Expat::Dispatched",
  "PREREQ_PM" => {
    "Carp" => 0,
    "XML::Parser::Expat" => 0,
    "parent" => 0,
    "strict" => 0,
    "true" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "Test::Warnings" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.952",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Test::Fatal" => 0,
  "Test::More" => 0,
  "Test::Warnings" => 0,
  "XML::Parser::Expat" => 0,
  "parent" => 0,
  "strict" => 0,
  "true" => 0,
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



