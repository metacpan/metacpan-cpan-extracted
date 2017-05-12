
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Wrapper to easily use Test::WWW::Mechanize with your Dancer apps",
  "AUTHOR" => "William Wolf <throughnothing\@gmail.com>, Grant McLean <grantm\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-WWW-Mechanize-Dancer",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::WWW::Mechanize::Dancer",
  "PREREQ_PM" => {
    "Cwd" => 0,
    "Dancer" => 0,
    "Module::Load" => 0,
    "Moose" => 0,
    "Test::WWW::Mechanize::PSGI" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0,
    "base" => 0,
    "lib" => 0
  },
  "VERSION" => "0.0100",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Cwd" => 0,
  "Dancer" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Load" => 0,
  "Moose" => 0,
  "Test::More" => 0,
  "Test::WWW::Mechanize::PSGI" => 0,
  "base" => 0,
  "lib" => 0,
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



