
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Configuration management framework",
  "AUTHOR" => "Adam Flott <adam\@npjh.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Thorium",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Thorium",
  "PREREQ_PM" => {
    "Class::MOP" => 0,
    "DateTime" => 0,
    "Devel::Symdump" => 0,
    "File::Find::Rule" => 0,
    "File::Slurp" => 0,
    "Hash::Merge::Simple" => 0,
    "Hobocamp" => 0,
    "IO::Interactive" => 0,
    "IPC::Cmd" => 0,
    "LWP" => 0,
    "Log::Log4perl" => 0,
    "Moose" => 0,
    "MooseX::Role::Strict" => 0,
    "MooseX::Types" => 0,
    "Params::Util" => 0,
    "Proc::ProcessTable" => 0,
    "Regexp::Common" => 0,
    "Sub::Exporter" => 0,
    "Sys::HostAddr" => 0,
    "Sys::HostIP" => 0,
    "Sys::Info" => 0,
    "Template" => 0,
    "Try::Tiny" => 0,
    "YAML::XS" => 0,
    "indirect" => 0
  },
  "VERSION" => "0.510",
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



