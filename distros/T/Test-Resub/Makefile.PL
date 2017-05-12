use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME                => 'Test::Resub',
  AUTHOR              => 'Belden Lyman <belden@cpan.org>',
  VERSION_FROM        => 'lib/Test/Resub.pm',
  ABSTRACT_FROM       => 'lib/Test/Resub.pm',
  PL_FILES            => {},
  PREREQ_PM => {
    'Test::More'      => 0,
    'Scalar::Util'    => 0,
    'Storable'        => 0,
  },
  META_MERGE => {
    resources => {
      bugtracker => 'https://github.com/belden/test-resub/issues',
      homepage   => 'https://github.com/belden/test-resub',
      repository => 'git://github.com/belden/test-resub.git',
    },
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => 'Test-Resub-*' },
);
