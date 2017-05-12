
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Integrate the Perl debugger with Vim",
  "AUTHOR" => "Eric Johnson <kablamo at iijo dot nospamthanks dot org>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Find" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "List::Util" => 0,
    "Net::Telnet" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Vim-Debug",
  "EXE_FILES" => [
    "bin/vdd",
    "bin/vimdebug-install"
  ],
  "LICENSE" => "perl",
  "NAME" => "Vim::Debug",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Dir::Self" => 0,
    "File::Basename" => 0,
    "File::Copy::Recursive" => 0,
    "File::Path" => 0,
    "Getopt::Long" => 0,
    "IO::Pty" => 0,
    "IPC::Run" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util" => 0,
    "MooseX::ClassAttribute" => 0,
    "POE" => 0,
    "POE::Component::Server::TCP" => 0,
    "Try::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.904",
  "test" => {
    "TESTS" => "t/*.t"
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



