
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Moose-based Test::Class replacement',
  'AUTHOR' => 'Jonathan Rockway <jrockway@cpan.org>',
  'BUILD_REQUIRES' => {
    'MooseX::Declare' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Test-Sweet',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Test::Sweet',
  'PREREQ_PM' => {
    'Devel::Declare' => '0',
    'Devel::Declare::Context::Simple' => '0',
    'List::MoreUtils' => '0',
    'Moose' => '0',
    'Moose::Exporter' => '0',
    'Moose::Meta::Class' => '0',
    'Moose::Role' => '0',
    'Moose::Util' => '0',
    'Moose::Util::MetaRole' => '0',
    'MooseX::Getopt' => '0',
    'MooseX::Runnable' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0',
    'Sub::Name' => '0',
    'Test::Builder' => '0',
    'Test::More' => '0',
    'Try::Tiny' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.03',
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



