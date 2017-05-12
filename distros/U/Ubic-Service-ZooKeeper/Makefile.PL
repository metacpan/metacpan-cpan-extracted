
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'running ZooKeeper as Ubic service',
  'AUTHOR' => 'Yury Zavarin <yury.zavarin@gmail.com>',
  'BUILD_REQUIRES' => {
    'File::Temp' => '0',
    'Perl6::Slurp' => '0',
    'Test::Class' => '0',
    'Test::More' => '0',
    'Test::TCP' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Ubic-Service-ZooKeeper',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Ubic::Service::ZooKeeper',
  'PREREQ_PM' => {
    'File::Copy' => '0',
    'File::Spec::Functions' => '0',
    'IO::Socket::INET' => '0',
    'Params::Validate' => '0',
    'Storable' => '0',
    'Time::HiRes' => '0',
    'Ubic::Daemon' => '0',
    'Ubic::Result' => '0',
    'Ubic::Service::Common' => '0',
    'parent' => '0'
  },
  'VERSION' => '0.02',
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



