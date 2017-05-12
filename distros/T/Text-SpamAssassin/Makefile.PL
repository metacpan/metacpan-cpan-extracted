
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Detects spamminess of arbitrary text, suitable for wiki and blog defense',
  'AUTHOR' => 'Robert Norris <rob@eatenbyagrue.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Text-SpamAssassin',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Text::SpamAssassin',
  'PREREQ_PM' => {
    'Data::Random' => '0',
    'Mail::Address' => '0',
    'Mail::Header' => '0',
    'Mail::Internet' => '0',
    'Mail::SpamAssassin' => '2'
  },
  'VERSION' => '2.001',
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



