# This Makefile.PL for YAMLTest was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.49.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.016000;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Write tests in YAML/YAMLScript",
  "AUTHOR" => "Ingy d\x{f6}t Net <ingy\@ingy.net>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "YAMLTest",
  "EXE_FILES" => [
    "bin/yamltest"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.016000",
  "NAME" => "YAMLTest",
  "PREREQ_PM" => {
    "Test::More::YAMLScript" => "v0.1.6"
  },
  "VERSION" => "0.1.0",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Test::More::YAMLScript" => "0.1.6"
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

package MY; use lib 't/lib'; use DistTestFixer;
sub postamble { $_[0]->SUPER::postamble . DistTestFixer->fix('yamltest') }
