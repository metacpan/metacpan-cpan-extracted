use 5.018;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Text::ANSITable::SQLStyleSheet',
  VERSION_FROM      => 'lib/Text/ANSITable/SQLStyleSheet.pm', # finds $VERSION
  PREREQ_PM         => {
  },
  TEST_REQUIRES       => {
    'Test::More'      => 0,
    'Text::ANSITable' => 0,
    'JSON'            => 0,
    'DBD::SQLite'     => '1.5',
    # http://www.cpantesters.org/cpan/report/e9b3793a-6bf8-1014-8785-51182680d7e9
    'DBI'             => '1.635',
  },
  ($] >= 5.005 ?     
    (ABSTRACT_FROM  => 'lib/Text/ANSITable/SQLStyleSheet.pm', # retrieve abstract from module
     AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),

  LICENSE           => 'perl',
  'dist'            => {
    PREOP     => 'chmod 600 Makefile.PL',
    TARFLAGS	=> '--group=none --owner=bjoern --mode=a+rw -cvf',
  },
  META_MERGE        => {
    'meta-spec' => { version => 2 },
    resources => {
       repository => {
         type => 'git',
         url  => 'https://github.com/hoehrmann/Text-ANSITable-SQLStyleSheet.git',
         web  => 'https://github.com/hoehrmann/Text-ANSITable-SQLStyleSheet',
      },
    },
  },
);

