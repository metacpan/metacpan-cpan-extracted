
use strict;
use warnings;

use 5.008008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl Module Tools",
  "AUTHOR" => "Mark Leighton Fisher <markleightonfisher\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "pmtools",
  "EXE_FILES" => [
    "bin/basepods",
    "bin/faqpods",
    "bin/modpods",
    "bin/pfcat",
    "bin/plxload",
    "bin/pmall",
    "bin/pman",
    "bin/pmcat",
    "bin/pmcheck",
    "bin/pmdesc",
    "bin/pmeth",
    "bin/pmexp",
    "bin/pmfunc",
    "bin/pminclude",
    "bin/pminst",
    "bin/pmload",
    "bin/pmls",
    "bin/pmpath",
    "bin/pmvers",
    "bin/podgrep",
    "bin/podpath",
    "bin/pods",
    "bin/podtoc",
    "bin/sitepods",
    "bin/stdpods"
  ],
  "LICENSE" => "perl",
  "NAME" => "pmtools",
  "PREREQ_PM" => {},
  "TEST_REQUIRES" => {},
  "VERSION" => "2.0.0",
  "test" => {
    "TESTS" => "t/*.t t/lib/*.t"
  }
);


my %FallbackPrereqs = ();


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



