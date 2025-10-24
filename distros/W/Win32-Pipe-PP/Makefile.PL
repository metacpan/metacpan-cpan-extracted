use strict;
use warnings;

use ExtUtils::MakeMaker;

die "OS unsupported\n" if $^O eq 'cygwin';

use ExtUtils::MakeMaker;

WriteMakefile1(
  NAME          => 'Win32::Pipe::PP',
  VERSION_FROM  => 'lib/Win32/Pipe/PP.pm',
  ABSTRACT_FROM => 'lib/Win32/Pipe/PP.pm',
  AUTHOR        => 'J. Schneider',
  LICENSE       => 'mit',

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 6.56,
  },

  PREREQ_PM     => {
    'Win32::API' => 0.77,
    'Win32::IPC' => 1.06,
  },

  TEST_REQUIRES => {
    'Test::More' => 0,
  },

  META_MERGE => {
    'meta-spec' => { 
      version => 2 
    },
    resources   => {
      repository  => {
        type => 'git',
        url  => 'https://github.com/brickpool/Win32-Pipe-PP.git',
        web  => 'https://github.com/brickpool/Win32-Pipe-PP',
      },
      bugtracker  => {
        web => 'https://github.com/brickpool/Win32-Pipe-PP/issues',
      },
    },
    prereqs => {
      runtime => {
        requires => {
          'Carp'           => 0,
          'Exporter'       => 0,
          'Win32'          => 0,
          'Win32API::File' => 0,
        },
      },
      test => {
        requires => {
          'Config' => 0,
        },
      },
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
    FILES => 'Win32-Pipe-*',
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
