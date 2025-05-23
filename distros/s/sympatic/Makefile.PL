# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.016000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A more producive perl thanks to CPAN",
  "AUTHOR" => "the sympa community <sympa-developpers\@lists.renater.fr>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "sympatic",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.016000",
  "NAME" => "sympatic",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Function::Parameters" => "2.001003",
    "Import::Into" => "1.002005",
    "Moo" => "2.002005",
    "MooX::LvalueAttribute" => "0.16",
    "Path::Tiny" => "0.0104",
    "Types::Standard" => "1.002001",
    "utf8::all" => "0.024"
  },
  "TEST_REQUIRES" => {
    "Class::Load" => 0,
    "Test::CheckManifest" => "0.9",
    "Test::Kwalitee" => "1.27",
    "Test::Kwalitee::Extra" => "0.4.0",
    "Test::Pod" => "1.22",
    "Test::Pod::Coverage" => "1.08",
    "Test::Simple" => "1.302120"
  },
  "VERSION" => "0.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::Load" => 0,
  "Function::Parameters" => "2.001003",
  "Import::Into" => "1.002005",
  "Moo" => "2.002005",
  "MooX::LvalueAttribute" => "0.16",
  "Path::Tiny" => "0.0104",
  "Test::CheckManifest" => "0.9",
  "Test::Kwalitee" => "1.27",
  "Test::Kwalitee::Extra" => "0.4.0",
  "Test::Pod" => "1.22",
  "Test::Pod::Coverage" => "1.08",
  "Test::Simple" => "1.302120",
  "Types::Standard" => "1.002001",
  "utf8::all" => "0.024"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
