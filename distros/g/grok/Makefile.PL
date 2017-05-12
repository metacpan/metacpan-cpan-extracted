
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl 6 documentation reader",
  "AUTHOR" => "Hinrik \303\226rn Sigur\303\260sson <hinrik.sig\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.47",
    "Test::Script" => "1.07"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "grok",
  "EXE_FILES" => [
    "bin/grok"
  ],
  "LICENSE" => "artistic_2",
  "NAME" => "grok",
  "PREREQ_PM" => {
    "File::HomeDir" => 0,
    "File::ShareDir" => 0,
    "File::Temp" => 0,
    "Getopt::Long" => "2.33",
    "IO::Interactive" => 0,
    "IO::Socket::SSL" => 0,
    "LWP::UserAgent" => 0,
    "Perl6::Doc" => "0.47",
    "Perl6::Perldoc" => "0.0.5",
    "Perl6::Perldoc::To::Ansi" => "0.07",
    "Pod::Parser" => "1.36",
    "Pod::Text::Ansi" => "0.04",
    "Pod::Xhtml" => 0
  },
  "VERSION" => "0.26",
  "test" => {
    "TESTS" => "t/*.t t/02_source/*.t t/03_opts/*.t t/04_targets/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



