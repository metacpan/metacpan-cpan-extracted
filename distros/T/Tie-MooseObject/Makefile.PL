
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'a tied hash interface to Moose object attributes',
  'AUTHOR' => 'Scott A. Beck <scottbeck@gmail.com>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Tie-MooseObject',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Tie::MooseObject',
  'PREREQ_PM' => {
    'Carp' => '0',
    'List::Util' => '1.23',
    'Moose::Util::TypeConstraints' => '1.03',
    'MooseX::Declare' => '0.33',
    'MooseX::Has::Sugar' => '0.0405',
    'MooseX::Types::Moose' => '0.12'
  },
  'VERSION' => '0.0001',
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



