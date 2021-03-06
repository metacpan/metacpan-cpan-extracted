# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.007.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "VMware vCloud Director",
  "AUTHOR" => "Phillip Pollard <bennie\@cpan.org>, Nigel Metheringham <nigelm\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "VMware-vCloud",
  "LICENSE" => "artistic_2",
  "NAME" => "VMware::vCloud",
  "PREREQ_PM" => {
    "Cache::Bounded" => "1.05",
    "Data::Dumper" => 0,
    "File::Slurp" => 0,
    "Getopt::Long" => 0,
    "LWP" => 5,
    "Term::Prompt" => 0,
    "XML::Simple" => 2
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => 0
  },
  "VERSION" => "2.404",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Cache::Bounded" => "1.05",
  "Data::Dumper" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Slurp" => 0,
  "File::Spec" => 0,
  "Getopt::Long" => 0,
  "LWP" => 5,
  "Term::Prompt" => 0,
  "Test::More" => 0,
  "XML::Simple" => 2
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
