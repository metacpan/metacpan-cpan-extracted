
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'PRANG implementation of the XML SRS protocol',
  'AUTHOR' => 'Catalyst SRS Team <team-srs@catalyst.net.nz>',
  'BUILD_REQUIRES' => {
    'XML::Compare' => '0.04'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'XML-SRS',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'XML::SRS',
  'PREREQ_PM' => {
    'Moose' => '1.21',
    'MooseX::Aliases' => '0.08',
    'MooseX::Params::Validate' => '0.15',
    'MooseX::Timestamp' => '0.06',
    'PRANG' => '0.14',
    'Regexp::Common' => '0'
  },
  'VERSION' => '0.09',
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



