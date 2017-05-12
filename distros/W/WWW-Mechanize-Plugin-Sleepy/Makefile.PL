
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A WWW::Mechanize plugin to provide the behaviour of WWW::Mechanize::Sleepy while using WWW::Mechanize::Pluggable",
  "AUTHOR" => "Michael Jemmeson <michael.jemmeson\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WWW-Mechanize-Plugin-Sleepy",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WWW::Mechanize::Plugin::Sleepy",
  "PREREQ_PM" => {
    "Carp" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Find" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "List::Util" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::Timer" => 0,
    "WWW::Mechanize::Pluggable" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Find" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "List::Util" => 0,
  "Test::Exception" => 0,
  "Test::More" => 0,
  "Test::Timer" => 0,
  "WWW::Mechanize::Pluggable" => 0,
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



