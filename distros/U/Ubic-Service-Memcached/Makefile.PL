
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'memcached as ubic service',
  'AUTHOR' => 'Vyacheslav Matyukhin <me@berekuk.ru>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Ubic-Service-Memcached',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Ubic::Service::Memcached',
  'PREREQ_PM' => {
    'Cache::Memcached' => '0',
    'Carp' => '0',
    'Morpheus' => '0',
    'Params::Validate' => '0',
    'Ubic::Daemon' => '0',
    'Ubic::Result' => '0',
    'Ubic::Service::Skeleton' => '0',
    'parent' => '0'
  },
  'VERSION' => '2.02',
  'test' => {
    'TESTS' => 't/*.t'
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



