use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  NAME => 'Test::Exception::LessClever',
  AUTHOR => 'Chad Granum <exodist7@gmail.com>',
  LICENSE => 'perl_5',
  ABSTRACT_FROM => 'lib/Test/Exception/LessClever.pm',
  VERSION_FROM => 'lib/Test/Exception/LessClever.pm',

  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 0,
    resources => {
      repository => {
        url => 'https://github.com/exodist/Test-Exception-LessClever.git',
        web => 'https://github.com/exodist/Test-Exception-LessClever',
        type => 'git',
      },
      homepage => 'https://github.com/exodist/Test-Exception-LessClever',
      bugtracker => {
        web => 'https://github.com/exodist/Test-Exception-LessClever/issues',
      },
    },
    x_IRC => 'irc://irc.perl.org/#perl-qa',
    x_MailingList => 'http://lists.perl.org/list/perl-qa.html',
    x_authority => 'cpan:EXODIST',
    x_deprecated => 1,
  },

  META_ADD => {
    'meta-spec' => { version => 2 },
    prereqs => {
      configure => {
        requires => {
          'ExtUtils::MakeMaker'     => '0',
        },
      },
      runtime => {
        requires => {
          'Carp'                    => '0',
          'Exporter'                => '0',
          'Test::Builder'           => '0',
          'base'                    => '0',
          'strict'                  => '0',
          'warnings'                => '0',
          'perl'                    => '5.006',
        },
      },
      test => {
        requires => {
          'Mock::Quick'             => '1.100',
          'Test::Builder::Tester'   => '0',
          'Test::More'              => '0.88',
        },
      },
    },
  },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
           or exists $WriteMakefileArgs{$key};
  my $r = $WriteMakefileArgs{$key} = {
    %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
    %{delete $WriteMakefileArgs{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

die 'attention developer: you need to do a sane meta merge here!'
  if keys %{$WriteMakefileArgs{BUILD_REQUIRES}};

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
  if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
  if $eumm_version < 6.46;

delete $WriteMakefileArgs{LICENSE}
  if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);

# pod2text is in https://metacpan.org/release/podlators
system("pod2text $WriteMakefileArgs{VERSION_FROM} > README")
    if -f '.gitignore'
        and (not -e 'README' or (stat('README'))[9] < (stat($WriteMakefileArgs{VERSION_FROM}))[9]);
