# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Easily page, search, and sort DBIx::Class::ResultSets in a web context",
  "AUTHOR" => "Arthur Axel \"fREW\" Schmidt <frioux+cpan\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Web-Util-DBIC-Paging",
  "LICENSE" => "perl",
  "NAME" => "Web::Util::DBIC::Paging",
  "PREREQ_PM" => {
    "Sub::Exporter::Progressive" => "0.00101"
  },
  "TEST_REQUIRES" => {
    "DBIx::Class" => "0.0825",
    "SQL::Translator" => "0.11016",
    "Test::Deep" => "0.11",
    "Test::More" => "0.98",
    "parent" => 0
  },
  "VERSION" => "0.001004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "DBIx::Class" => "0.0825",
  "SQL::Translator" => "0.11016",
  "Sub::Exporter::Progressive" => "0.00101",
  "Test::Deep" => "0.11",
  "Test::More" => "0.98",
  "parent" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
