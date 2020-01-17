
use strict;
use warnings;

#BEGIN { require 5.9.4; }

use ExtUtils::MakeMaker 7.34;
use Module::Metadata;
my $meta_spec = 2;


my %WriteMakefileArgs = (
  'ABSTRACT_FROM' => 'lib/overload/open.pm',
  'AUTHOR' => 'Samantha McVey <samantham@posteo.net.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '7.34',
    'Module::Metadata' => 0,
  },
  'LICENSE' => 'perl',
  'META_MERGE' => {
    provides => Module::Metadata->provides( version => $meta_spec, dir => 'lib' ),
    'meta-spec' => { version => $meta_spec },
    'resources' => {
      'repository' => {
        'url' => 'https://github.com/samcv/perl-overload-open.git',
        'web' => 'https://github.com/samcv/perl-overload-open',
        'type' => 'git',
      },
    },
  },
  'NAME' => 'overload::open',
  'PREREQ_PM' => {},
  'VERSION_FROM' => 'lib/overload/open.pm',
  'test' => {
    'TESTS' => 't/*.t'
  },
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
