# This Makefile.PL for Text-Hspell was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.48.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.014;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "wrapper for the hspell (= Hebrew speller) library",
  "AUTHOR" => "Shlomi Fish <shlomif\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Text-Hspell",
  "LICENSE" => "mit",
  "MIN_PERL_VERSION" => "5.014",
  "NAME" => "Text::Hspell",
  "PREREQ_PM" => {
    "DynaLoader" => 0,
    "Encode" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88",
    "utf8" => 0
  },
  "VERSION" => "0.4.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

%WriteMakefileArgs = (
    %WriteMakefileArgs,
    'OBJECT' => 'Hspell.o',
    'LIBS' => [ "-lhspell -lz", ],
);

my %FallbackPrereqs = (
  "DynaLoader" => 0,
  "Encode" => 0,
  "Test::More" => "0.88",
  "strict" => 0,
  "utf8" => 0,
  "vars" => 0,
  "warnings" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
