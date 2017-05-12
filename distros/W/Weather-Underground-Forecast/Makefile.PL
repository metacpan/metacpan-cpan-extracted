
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Weather Underground Forecast Data',
  'AUTHOR' => 'Mateu X Hunter <hunter@missoula.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Weather-Underground-Forecast',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Weather::Underground::Forecast',
  'PREREQ_PM' => {
    'Data::Dumper::Concise' => '0',
    'LWP::Simple' => '0',
    'Moose' => '0',
    'XML::LibXML' => '0',
    'XML::Simple' => '0',
    'XML::Validate::LibXML' => '0',
    'namespace::autoclean' => '0',
    'strictures' => '1'
  },
  'VERSION' => '0.07',
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



