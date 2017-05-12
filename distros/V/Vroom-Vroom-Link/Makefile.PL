
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Subclass Vroom::Vroom to make clickable links',
  'AUTHOR' => 'Dr Bean <drbean at (a) cpan dot (.) org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0',
    'Vroom::Vroom' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Vroom-Vroom-Link',
  'EXE_FILES' => [
    'bin/vink'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Vroom::Vroom::Link',
  'PREREQ_PM' => {
    'IO::All' => '0',
    'Template::Toolkit::Simple' => '0',
    'Vroom' => '0',
    'parent' => '0'
  },
  'VERSION' => '0.06',
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



