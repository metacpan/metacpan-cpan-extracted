use strict;

use ExtUtils::MakeMaker;


my %args = (
  NAME => 'Thrust',
  VERSION_FROM => 'lib/Thrust.pm',
  LIBS => [''],
  INC => '-I lib/',
  PREREQ_PM => {
    'common::sense' => 0,
    'AnyEvent' => 0,
    'JSON::XS' => 0,
    'Scalar::Util' => 0,
    'Alien::Thrust' => 0,
  },
  LICENSE => 'perl',
  dist => {
    PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
  },
  META_MERGE => {
    resources => {
      repository => 'git://github.com/hoytech/Thrust.git',
      bugtracker => 'https://github.com/hoytech/Thrust/issues',
    },
  },
);

WriteMakefile(%args);
