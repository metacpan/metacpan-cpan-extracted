BEGIN {
  use strict; use warnings;
  unless(eval q{ use 5.008001; 1}) {
    print "Perl 5.008001 or better required\n";
    exit;
  }
}
# This file was automatically generated by Dist::Zilla::Plugin::Author::Plicease::MakeMaker v2.61.
use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT"           => "Compare a URL in your Test2 test",
  "AUTHOR"             => "Graham Ollis <plicease\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME"         => "Test2-Tools-URL",
  "LICENSE"          => "perl",
  "MIN_PERL_VERSION" => "5.008001",
  "NAME"             => "Test2::Tools::URL",
  "PM"               => {
    "lib/Test2/Tools/URL.pm" => "\$(INST_LIB)/Test2/Tools/URL.pm"
  },
  "PREREQ_PM" => {
    "Carp"                   => 0,
    "Test2::Compare"         => "0.000060",
    "Test2::Compare::Base"   => "0.000060",
    "Test2::Compare::Custom" => "0.000060",
    "Test2::Compare::Hash"   => "0.000060",
    "Test2::Compare::String" => "0.000060",
    "URI"                    => "1.61",
    "URI::QueryParam"        => 0
  },
  "TEST_REQUIRES" => {
    "Test2::V0" => "0.000121"
  },
  "VERSION" => "0.06",
  "test"    => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Carp"                   => 0,
  "Test2::Compare"         => "0.000060",
  "Test2::Compare::Base"   => "0.000060",
  "Test2::Compare::Custom" => "0.000060",
  "Test2::Compare::Hash"   => "0.000060",
  "Test2::Compare::String" => "0.000060",
  "Test2::V0"              => "0.000121",
  "URI"                    => "1.61",
  "URI::QueryParam"        => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);