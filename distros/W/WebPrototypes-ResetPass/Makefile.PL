
use strict;
use warnings;

BEGIN { require 5.0100; }

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => '(Experimental) Plack application for sending a \'Reset password link\' via email',
  'AUTHOR' => 'Zbigniew Lukasiak <zby@cpan.org>',
  'BUILD_REQUIRES' => {
    'Plack::Builder' => '0',
    'Test::More' => '0',
    'Test::WWW::Mechanize::PSGI' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'WebPrototypes-ResetPass',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'WebPrototypes::ResetPass',
  'PREREQ_PM' => {
    'Email::Sender::Simple' => '0',
    'Email::Simple' => '0',
    'Email::Simple::Creator' => '0',
    'Plack::Component' => '0',
    'Plack::Request' => '0',
    'String::Random' => '0',
    'URL::Encode' => '0',
    'parent' => '0'
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



