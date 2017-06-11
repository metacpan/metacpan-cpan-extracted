use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker;

my %FallbackPrereqs = (
  "Test::More" => "0.88",
);

my %WriteMakefileArgs = (
  "ABSTRACT_FROM" => "lib/YAML/Perl.pm",
  "AUTHOR" => [
    "Ingy döt Net <ingy\@cpan.org>",
    "Tina Müller <tinita\@cpan.org>",
  ],
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
  },
  "DISTNAME" => "YAML-Perl",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008001",
  "NAME" => "YAML::Perl",
  "PREREQ_PM" => {
    "YAML::PP::Parser" => '0.003',
  },
  "TEST_REQUIRES" => {
    %FallbackPrereqs,
  },
  "VERSION_FROM" => "lib/YAML/Perl.pm",

  "test" => {
    "RECURSIVE_TEST_FILES" => 1,
  },
);



unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
