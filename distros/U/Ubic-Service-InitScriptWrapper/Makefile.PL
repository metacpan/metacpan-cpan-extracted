
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "represent any /etc/init.d/ script as ubic service",
  "AUTHOR" => "Vyacheslav Matyukhin <mmcleric\@yandex-team.ru>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "Ubic::Result" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Ubic-Service-InitScriptWrapper",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Ubic::Service::InitScriptWrapper",
  "PREREQ_PM" => {
    "IPC::System::Simple" => 0,
    "Ubic::Service::Skeleton" => 0,
    "autodie" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.02",
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



