use lib 'inc';
use Devel::AssertOS qw[-MSWin32];

use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "locate .git root at compile time and use as lib path",
  "AUTHOR" => "Victor Efimov <efimov\@reg.ru>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "lib-gitroot",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "lib::gitroot",
  "PREREQ_PM" => {
    "Carp" => 0,
    "File::Spec" => 0,
    "Modern::Perl" => 0,
    "lib" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "File::Path" => 0,
    "File::Temp" => "0.16",
    "Test::Deep" => 0,
    "Test::More" => 0,
    "Test::Pod" => "1.22",
    "Test::Spec" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Capture::Tiny" => 0,
  "Carp" => 0,
  "File::Path" => 0,
  "File::Spec" => 0,
  "File::Temp" => "0.16",
  "Modern::Perl" => 0,
  "Module::Build" => "0.3601",
  "Test::Deep" => 0,
  "Test::More" => 0,
  "Test::Pod" => "1.22",
  "Test::Spec" => 0,
  "lib" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



