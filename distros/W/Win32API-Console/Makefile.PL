use strict;
use warnings;

use ExtUtils::MakeMaker;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
  die "OS unsupported\n";
}

WriteMakefile1(
  NAME             => 'Win32API::Console',
  VERSION_FROM     => 'lib/Win32API/Console.pm',
  ABSTRACT_FROM    => 'lib/Win32API/Console.pod',
  MIN_PERL_VERSION => '5.014',
  AUTHOR           => 'J. Schneider',
  LICENSE          => 'mit',

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 6.56,
  },

  PREREQ_PM => {
    'Win32::API'         => 0.77,
    'Win32::Console'     => '0.10',
  },

  TEST_REQUIRES => {
    'Test::More'     => 0.88,
    'File::Basename' => 0,
  },

  META_MERGE => {
    'meta-spec' => { 
      version => 2 
    },
    resources => {
      repository  => {
        type => 'git',
        url  => 'https://github.com/brickpool/Win32API-Console.git',
        web  => 'https://github.com/brickpool/Win32API-Console',
      },
      bugtracker  => {
        web => 'https://github.com/brickpool/Win32API-Console/issues',
      },
    },
    prereqs => {
      runtime => {
        requires => {
          'Encode'         => 0,
          'Exporter'       => 0,
          'Hash::Util'     => 0,
          'Win32'          => 0.44,
          'Win32API::File' => 0.08,
          'version'        => 0.77,
        },
        recommends => {
          'Pod::Autopod'       => 0,
          'Pod::Usage'         => 0,
          'Types::Standard'    => 0,
          'Win32::GuiTest'     => 0,
          'Win32API::Registry' => 0.21,
        },
      },
      # test => {
      #   requires => {
      #     'Config' => 0,
      #   },
      # },
    },
  },

  $^O =~/win/i ? (
    dist  => {
      TARFLAGS => '-cvzf',
      COMPRESS => 'perl -MExtUtils::Command -e test_f',
      POSTOP   => 'perl -MExtUtils::Command -e mv $(DISTVNAME).tar ' . 
        '$(DISTVNAME).tar$(SUFFIX)'
    },
  ) : (),
  clean => {
    FILES => 'Win32API-*',
  },
  test  => {
    TESTS => 't/*.t t/*/*.t'
  },
);


# Taken from eumm-upgrade by Alexandr Ciornii
sub WriteMakefile1 { # void (%params)
  my %params = @_;
  my $eumm_version = $ExtUtils::MakeMaker::VERSION;
  $eumm_version = eval $eumm_version;

  if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
    $params{BUILD_REQUIRES} = {
      %{$params{BUILD_REQUIRES} || {}},
      %{$params{TEST_REQUIRES}} 
    };
    delete $params{TEST_REQUIRES};
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM} = {
      %{$params{PREREQ_PM} || {}},
      %{$params{BUILD_REQUIRES}} 
    };
    delete $params{BUILD_REQUIRES};
  }

  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);
}
