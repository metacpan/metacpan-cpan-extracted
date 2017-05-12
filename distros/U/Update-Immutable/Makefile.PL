use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Update::Immutable',
    VERSION_FROM => 'lib/Update/Immutable.pm',
    PREREQ_PM => {
      'common::sense' => 0,
    },
    TEST_REQUIRES => {
      'Clone' => 0,
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/Update-Immutable-p5.git',
        bugtracker => 'https://github.com/hoytech/Update-Immutable-p5/issues',
      },
    },
);

WriteMakefile(%args);
