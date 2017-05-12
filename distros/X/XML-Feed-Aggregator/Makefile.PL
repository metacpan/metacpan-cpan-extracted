
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Simple feed aggregator',
  'AUTHOR' => 'Robin Edwards <robin.ge@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.94',
    'Test::NoWarnings' => '1.02',
    'Test::UseAllModules' => '0.13'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'XML-Feed-Aggregator',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'XML::Feed::Aggregator',
  'PREREQ_PM' => {
    'DateTime' => '0.66',
    'HTML::Scrubber' => '0.08',
    'Moose' => '1.24',
    'MooseX::Types' => '0.25',
    'MooseX::Types::URI' => '0.02',
    'Try::Tiny' => '0.09',
    'URI' => '1.58',
    'XML::Feed' => '0.43',
    'namespace::autoclean' => '0.12'
  },
  'VERSION' => '0.0401',
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



