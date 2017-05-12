
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A Template Toolkit renderer for WebNano with dynamic search paths',
  'AUTHOR' => 'Zbigniew Lukasiak <zby@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0',
    'WebNano::Controller' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'WebNano-Renderer-TT',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'WebNano::Renderer::TT',
  'PREREQ_PM' => {
    'File::Spec' => '0',
    'Object::Tiny::RW' => '0',
    'Template' => '0'
  },
  'VERSION' => '0.002',
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



