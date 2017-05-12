use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'Test::Easy',
  AUTHOR         => 'Belden Lyman <belden@cpan.org>',
  VERSION_FROM   => 'lib/Test/Easy.pm',
  ABSTRACT_FROM  => 'lib/Test/Easy.pm',
  PL_FILES => {},
  PREREQ_PM => {
     'Data::Denter'        => 0,       # for deep_equal and deep_ok
     'Data::Difflet'       => 0.06,    # for deep_equal and deep_ok
     'Functional::Utility' => 1.02,
     'Hash::MostUtils'     => 1.05,
     'Scalar::Util'        => 0,
     'Test::More'          => 0,
     'Test::Resub'         => 0,
  },
  META_MERGE => {
    resources => {
      bugtracker => 'https://github.com/belden/perl-test-easy/issues',
      homepage   => 'https://github.com/belden/perl-test-easy',
      repository => 'git://github.com/belden/perl-test-easy.git',
    },
  },
  LICENSE => 'perl',
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Test-Easy-*' },
);
