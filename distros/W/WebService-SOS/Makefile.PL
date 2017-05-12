
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A module for interfacing with an OpenGIS Sensor Observation Service (SOS)',
  'AUTHOR' => 'James C. Davis <jdavis@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0',
    'strict' => '0',
    'warnings' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'WebService-SOS',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'WebService::SOS',
  'PREREQ_PM' => {
    'Carp' => '0',
    'HTTP::Request::Common' => '0',
    'LWP::UserAgent' => '0',
    'Moose' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'URI::Escape' => '0',
    'XML::Rabbit' => '0',
    'XML::Rabbit::Root' => '0.1.0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.01',
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



