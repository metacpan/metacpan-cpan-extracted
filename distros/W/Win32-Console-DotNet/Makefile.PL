use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

die "OS unsupported\n" if $^O ne 'MSWin32';

WriteMakefile(
  NAME              => 'Win32::Console::DotNet',
  VERSION_FROM      => 'lib/Win32/Console/DotNet.pm',
  ABSTRACT_FROM     => 'lib/Win32/Console/DotNet.pm',
  MIN_PERL_VERSION  => '5.014',
  AUTHOR            => 'J. Schneider',
  LICENSE           => 'mit',
  EXE_FILES         => [],
  PL_FILES          => {},

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 6.64,
  },

  PREREQ_PM => {
    'Class::Method::Modifiers'  => 2.11,
    'Class::Tiny'               => "1.000",
    'Class::Tiny::Antlers'      => 0.024,
    'Devel::StrictMode'         => 0.003,
    'IO::Null'                  => 1.01,
    'namespace::sweep'          => 0.006,
    'PerlX::Assert'             => 0.905,
    'Type::Nano'                => 0.014,
    'Win32'                     => 0.54,
    'Win32::API'                => 0.79,
    'Win32::Console'            => "0.10",
    'Win32API::File'            => 0.1201,
  },

  TEST_REQUIRES => {
    'Perl::OSType'    => 1.009,
    'Test::Exception' => 0.43,
    'Test::Simple'    => 1.302188,
  },

  META_MERGE  => {
    'meta-spec' => { 
      version => 2 
    },
    homepage    => 'http://brickpool.de',
    resources   => {
      repository  => {
        type => 'git',
        url  => 'https://github.com/brickpool/Win32-Console-DotNet.git',
        web  => 'https://github.com/brickpool/Win32-Console-DotNet',
      },
      bugtracker  => {
        web => 'https://github.com/brickpool/Win32-Console-DotNet/issues',
      },
    },
    prereqs => {
      runtime => {
        requires => { # v5.14 builtin modules
          'Config'            => 0,
          'constant'          => 0,
          'Encode'            => 0,
          'Encode::Alias'     => 0,
          'Encode::Byte'      => 0,
          'Encode::Encoding'  => 0,
          'Encode::Unicode'   => 0,
          'English'           => 0,
          'Exporter'          => 0,
          'IO::File'          => 0,
          'IO::Handle'        => 0,
          'List::Util'        => 0,
          'strict'            => 0,
          'Symbol'            => 0,
          'threads'           => 0,
          'threads::shared'   => 0,
          'warnings'          => 0,
        },
        recommends => {
          'bytes'         => 0,
          'Capture::Tiny' => 0,
          'CLDR::Number'  => 0,
          'DateTime'      => 0,
          'HTTP::Date'    => 0,
          'Time::HiRes'   => 0,
          'Time::Piece'   => 0,
          'Type::Tiny'    => 0,
        },
      },
      test => {
        requires => { # v5.14 builtin modules
          'autodie'           => 0,
          'FindBin'           => 0,
          'IPC::Open3'        => 0,
          'POSIX'             => 0,
          'Scalar::Util'      => 0,
          'Time::HiRes'       => 0,
        },
      },
    },
  },

  dist  => {
    TARFLAGS => '-cvzf',
    COMPRESS => 'perl -MExtUtils::Command -e test_f',
    POSTOP   => 'perl -MExtUtils::Command -e mv $(DISTVNAME).tar ' . 
      '$(DISTVNAME).tar$(SUFFIX)'
  },
  clean => {
    FILES => 'Win32-Console-*',
  },
  test  => {
    TESTS => 't/*.t t/*/*.t'
  },
);
