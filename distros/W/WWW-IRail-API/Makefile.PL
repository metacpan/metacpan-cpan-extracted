
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A wrapper for the iRail.be API',
  'AUTHOR' => 'Tim Esselens <tim.esselens@gmail.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'WWW-IRail-API',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'WWW::IRail::API',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Date::Format' => '0',
    'DateTime::Format::Natural' => '0',
    'FindBin' => '0',
    'HTTP::Request' => '0',
    'HTTP::Request::Common' => '0',
    'HTTP::Response' => '0',
    'JSON::XS' => '0',
    'LWP' => '0',
    'LWP::UserAgent' => '0',
    'Test::Deep' => '0',
    'Test::Most' => '0',
    'XML::Simple' => '0',
    'YAML' => '0',
    'common::sense' => '0',
    'parent' => '0'
  },
  'VERSION' => '0.003',
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



