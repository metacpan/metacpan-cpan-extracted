# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Try hard to get the functionality of Syntax::Keyword::Try",
  "AUTHOR" => "Steve Scaffidi <sscaffidi\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Try-Harder",
  "LICENSE" => "perl",
  "NAME" => "Try::Harder",
  "PREREQ_PM" => {
    "Filter::Simple" => 0,
    "Import::Into" => 0,
    "Module::Load::Conditional" => 0,
    "Text::Balanced" => 0,
    "if" => 0
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Filter::Simple" => 0,
  "Import::Into" => 0,
  "Module::Load::Conditional" => 0,
  "Text::Balanced" => 0,
  "if" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
