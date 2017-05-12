
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A minimalistic PSGI based web framework.',
  'AUTHOR' => 'Zbigniew Lukasiak <zby@cpan.org>',
  'BUILD_REQUIRES' => {
    'Cwd' => '0',
    'File::Copy' => '0',
    'File::Spec::Functions' => '0',
    'HTTP::Request::Common' => '0',
    'Plack::Test' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'WebNano',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'WebNano',
  'PREREQ_PM' => {
    'Class::Load' => '0',
    'Encode' => '0',
    'Exporter' => '0',
    'File::Spec' => '0',
    'Object::Tiny::RW' => '0',
    'Plack::Request' => '0.9967',
    'Plack::Response' => '0.9967',
    'Scalar::Util' => '0',
    'Template::Tiny' => '0',
    'URI::Escape' => '0'
  },
  'VERSION' => '0.007',
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



