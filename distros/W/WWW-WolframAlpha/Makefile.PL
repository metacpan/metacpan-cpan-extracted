
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Perl extension for the WolframAlpha API',
  'AUTHOR' => 'Gabriel Weinberg <yegg@alum.mit.edu>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'WWW-WolframAlpha',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'WWW::WolframAlpha',
  'PREREQ_PM' => {
    'HTTP::Request::Common' => '5.824',
    'LWP::UserAgent' => '5.827',
    'URI::Escape' => '3.29',
    'XML::Simple' => '2.18'
  },
  'VERSION' => '1.10',
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



