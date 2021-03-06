# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.014.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Bind Perl data structures into XML",
  "AUTHOR" => "Neil Kirsopp <cpan\@pneumatoscopic.net>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "xml-binddata",
  "LICENSE" => "perl",
  "NAME" => "xml::binddata",
  "PREREQ_PM" => {
    "XML::LibXML" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Mock::Simple" => 0,
    "Test::More" => 0,
    "Test::Warnings" => 0
  },
  "VERSION" => "0.3.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Test::Mock::Simple" => 0,
  "Test::More" => 0,
  "Test::Warnings" => 0,
  "XML::LibXML" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
