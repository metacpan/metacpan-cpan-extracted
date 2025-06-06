# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.034.
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Returns your ip address using L<http://curlmyip.com>",
  "AUTHOR" => "David Farrell <dfarrell\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "WWW-curlmyip",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "WWW::curlmyip",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "HTTP::Tiny" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0,
    "Test::RequiresInternet" => "0.03"
  },
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "HTTP::Tiny" => 0,
  "Test::More" => 0,
  "Test::RequiresInternet" => "0.03",
  "base" => 0,
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
