
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "POEditor.com API wrapper",
  "AUTHOR" => "Roman F. <romanf\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-POEditor",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WebService::POEditor",
  "PREREQ_PM" => {
    "Moose" => 0,
    "MooseX::Attribute::ENV" => 0,
    "Role::REST::Client" => 0,
    "namespace::clean" => 0,
    "version" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Most" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "v1.1.0",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Moose" => 0,
  "MooseX::Attribute::ENV" => 0,
  "Role::REST::Client" => 0,
  "Test::Most" => 0,
  "namespace::clean" => 0,
  "strict" => 0,
  "version" => 0,
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



