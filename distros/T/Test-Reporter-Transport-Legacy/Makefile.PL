
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Legacy Test::Reporter::Transport modules',
  'AUTHOR' => 'Adam J. Foxson <afoxson@pobox.com>, David Golden <dagolden@cpan.org>, Kirrily "Skud" Robert <skud@cpan.org>, Ricardo Signes <rjbs@cpan.org>, Richard Soderberg <rsod@cpan.org>, Kurt Starsinic <Kurt.Starsinic@isinet.com>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0.88',
    'Test::Reporter' => '1.58',
    'vars' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Test-Reporter-Transport-Legacy',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Test::Reporter::Transport::Legacy',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Encode' => '0',
    'LWP::UserAgent' => '0',
    'MIME::QuotedPrint' => '0',
    'Mail::Send' => '0',
    'Net::SMTP' => '0',
    'Net::SMTP::TLS' => '0',
    'Test::Reporter::Transport' => '1.58',
    'bytes' => '0'
  },
  'VERSION' => '1.59',
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



