# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.029.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 7.64;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Interact with the Hydra service API",
  "AUTHOR" => "DERIV <DERIV\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.64"
  },
  "DISTNAME" => "WebService-Hydra",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "WebService::Hydra",
  "PREREQ_PM" => {
    "Crypt::JWT" => 0,
    "HTTP::Tiny" => 0,
    "JSON::MaybeUTF8" => 0,
    "Log::Any" => 0,
    "Module::Load" => 0,
    "Object::Pad" => "0.56",
    "Scalar::Util" => 0,
    "Syntax::Keyword::Try" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Log::Any::Test" => 0,
    "Test::CheckDeps" => "0.010",
    "Test::Deep" => 0,
    "Test::Exception" => 0,
    "Test::MockModule" => 0,
    "Test::More" => "0.94"
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t t/unit/*.t"
  }
);


my %FallbackPrereqs = (
  "Crypt::JWT" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "HTTP::Tiny" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "JSON::MaybeUTF8" => 0,
  "Log::Any" => 0,
  "Log::Any::Test" => 0,
  "Module::Load" => 0,
  "Object::Pad" => "0.56",
  "Scalar::Util" => 0,
  "Syntax::Keyword::Try" => 0,
  "Test::CheckDeps" => "0.010",
  "Test::Deep" => 0,
  "Test::Exception" => 0,
  "Test::MockModule" => 0,
  "Test::More" => "0.94",
  "constant" => 0,
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
