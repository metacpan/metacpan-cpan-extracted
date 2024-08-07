# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.030.
use strict;
use warnings;

use 5.012000;

use ExtUtils::MakeMaker 6.78;

my %WriteMakefileArgs = (
  "ABSTRACT" => "composable units of assertion",
  "AUTHOR" => "Ricardo Signes <cpan\@semiotic.systems>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.78"
  },
  "DISTNAME" => "Test-Routine",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.012000",
  "NAME" => "Test::Routine",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Load" => 0,
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Meta::Class" => 0,
    "Moose::Meta::Method" => 0,
    "Moose::Role" => 0,
    "Moose::Util" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Params::Util" => 0,
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "Sub::Exporter::Util" => 0,
    "Test2::API" => "1.302045",
    "Test::Abortable" => "0.002",
    "Test::More" => "0.96",
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Math::Trig" => 0,
    "Test::Builder::Tester" => 0,
    "Test::Fatal" => 0,
    "Test::Moose" => 0,
    "Test::More" => "0.96",
    "lib" => 0
  },
  "VERSION" => "0.031",
  "test" => {
    "TESTS" => "t/*.t t/demo/*.t t/todo/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::Load" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Math::Trig" => 0,
  "Moose" => 0,
  "Moose::Exporter" => 0,
  "Moose::Meta::Class" => 0,
  "Moose::Meta::Method" => 0,
  "Moose::Role" => 0,
  "Moose::Util" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "Params::Util" => 0,
  "Scalar::Util" => 0,
  "Sub::Exporter" => 0,
  "Sub::Exporter::Util" => 0,
  "Test2::API" => "1.302045",
  "Test::Abortable" => "0.002",
  "Test::Builder::Tester" => 0,
  "Test::Fatal" => 0,
  "Test::Moose" => 0,
  "Test::More" => "0.96",
  "Try::Tiny" => 0,
  "lib" => 0,
  "namespace::autoclean" => 0,
  "namespace::clean" => 0,
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
