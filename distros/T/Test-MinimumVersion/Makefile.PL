# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.029.
use strict;
use warnings;

use 5.008000;

use ExtUtils::MakeMaker 6.78;

my %WriteMakefileArgs = (
  "ABSTRACT" => "does your code require newer perl than you think?",
  "AUTHOR" => "Ricardo Signes",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.78"
  },
  "DISTNAME" => "Test-MinimumVersion",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008000",
  "NAME" => "Test::MinimumVersion",
  "PREREQ_PM" => {
    "CPAN::Meta" => 0,
    "Exporter" => 0,
    "File::Find::Rule" => 0,
    "File::Find::Rule::Perl" => 0,
    "Perl::MinimumVersion" => "1.32",
    "Test::Builder" => 0,
    "base" => 0,
    "strict" => 0,
    "version" => "0.70",
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => "0.96",
    "Test::Tester" => 0
  },
  "VERSION" => "0.101083",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "CPAN::Meta" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Find::Rule" => 0,
  "File::Find::Rule::Perl" => 0,
  "File::Spec" => 0,
  "Perl::MinimumVersion" => "1.32",
  "Test::Builder" => 0,
  "Test::More" => "0.96",
  "Test::Tester" => 0,
  "base" => 0,
  "strict" => 0,
  "version" => "0.70",
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
