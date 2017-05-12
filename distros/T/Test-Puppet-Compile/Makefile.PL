
use strict;
use warnings;

use 5.010_000;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Puppet catalog testing",
  "AUTHOR" => "Dominik Schulz <dominik.schulz\@gauner.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Test-Puppet-Compile",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::Puppet::Compile",
  "PREREQ_PM" => {
    "File::Basename" => 0,
    "File::ShareDir" => 0,
    "File::Temp" => 0,
    "Moose" => 0,
    "Template" => 0,
    "Test::More" => 0,
    "Try::Tiny" => 0,
    "feature" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Basename" => 0,
  "File::ShareDir" => 0,
  "File::Temp" => 0,
  "Moose" => 0,
  "Template" => 0,
  "Test::More" => 0,
  "Try::Tiny" => 0,
  "feature" => 0,
  "mro" => 0,
  "namespace::autoclean" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


