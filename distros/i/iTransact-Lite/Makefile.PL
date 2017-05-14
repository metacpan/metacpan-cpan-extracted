
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A simple interface to the iTransact payment gateway.',
  'AUTHOR' => 'JT Smith <jt@plainblack.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'iTransact-Lite',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'iTransact::Lite',
  'PREREQ_PM' => {
    'Any::Moose' => '0.13',
    'Digest::HMAC_SHA1' => '1.01',
    'LWP' => '6.02',
    'LWP::Protocol::https' => '6.02',
    'Mozilla::CA' => '20110409',
    'Ouch' => '0.0400',
    'Test::More' => '0',
    'XML::Hash::LX' => '0.06'
  },
  'VERSION' => '0.0101',
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



