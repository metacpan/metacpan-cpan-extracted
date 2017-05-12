
use strict;
use warnings;

use 5.010_000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A simple abstraction of the Zabbix::API",
  "AUTHOR" => "Dominik Schulz <dominik.schulz\@gauner.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Zabbix-API-Simple",
  "EXE_FILES" => [
    "bin/zbx-sapi-web.pl",
    "bin/zbx-sapi-web.psgi",
    "bin/zbx-sapi.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Zabbix::API::Simple",
  "PREREQ_PM" => {
    "Config::Yak" => 0,
    "Config::Yak::LazyConfig" => 0,
    "Log::Tree" => 0,
    "Log::Tree::Logger" => 0,
    "Module::Pluggable" => 0,
    "Moose" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "Plack::Loader" => 0,
    "Plack::Request" => 0,
    "Try::Tiny" => 0,
    "Zabbix::API" => 0,
    "Zabbix::API::Host" => 0,
    "feature" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.01",
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



