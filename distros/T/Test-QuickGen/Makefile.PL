use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Test::QuickGen',
  AUTHOR => [
    'Antonis Kalou <kalouantonis@protonmail.com>',
  ],
  LICENSE => 'perl_5',
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/antoniskalou/Test-QuickGen.git',
        web => 'https://github.com/antoniskalou/Test-QuickGen',
      },
      bugtracker => {
        web => 'https://github.com/antoniskalou/Test-QuickGen/issues'
      },
    },
  },
  VERSION_FROM => 'lib/Test/QuickGen.pm',
  EXE_FILES => ['bin/quicktest'],
  MIN_PERL_VERSION => '5.16.0',
  TEST_REQUIRES => {
    'Test::More' => 0,
  }
);
