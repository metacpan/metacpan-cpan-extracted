
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Provides interface to SlimTimer web service.',
  'AUTHOR' => 'Vadim Zeitlin <vz-cpan@zeitlins.org>',
  'BUILD_REQUIRES' => {
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'WebService-SlimTimer',
  'EXE_FILES' => [
    'bin/slimtimer-report'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'WebService::SlimTimer',
  'PREREQ_PM' => {
    'DateTime' => '0',
    'DateTime::Format::Natural' => '0',
    'DateTime::Format::RFC3339' => '0',
    'File::Slurp' => '0',
    'File::Spec' => '0',
    'Getopt::Long::Descriptive' => '0',
    'LWP::UserAgent' => '0',
    'Moose' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Declare' => '0',
    'MooseX::Method::Signatures' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0',
    'YAML::XS' => '0'
  },
  'VERSION' => '0.005',
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



