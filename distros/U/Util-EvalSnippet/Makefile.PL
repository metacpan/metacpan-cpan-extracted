use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Util::EvalSnippet',
  AUTHOR           => q{Clive Holloway <clive.holloway@gmail.com>},
  VERSION_FROM     => 'lib/Util/EvalSnippet.pm',
  ABSTRACT_FROM    => 'lib/Util/EvalSnippet.pm',
  LICENSE          => 'gpl',
  PL_FILES         => {},
  EXE_FILES        => ['script/perl-eval-snippet'],
  MIN_PERL_VERSION => 5.012,
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
  },
  BUILD_REQUIRES   => {
    'Test::More'   => 0,
  },
  PREREQ_PM => {
    'PadWalker'    => 0,
    'File::Slurp'  => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Util-EvalSnippet-*' },
  test => {
    TESTS => 't/tests/*/*/*.t',
  }
);

