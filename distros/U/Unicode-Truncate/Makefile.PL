use strict;

use ExtUtils::MakeMaker;

# Commented out for distribution by Inline::Module::LeanDist
#use Inline::Module::LeanDist::MakefilePL;

my %args = (
    NAME => 'Unicode::Truncate',
    VERSION_FROM => 'lib/Unicode/Truncate.pm',
    PREREQ_PM => {
    },
    TEST_REQUIRES => {
      'Test::More' => 0,
      'Test::Exception' => 0,
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    postamble => {
      inline => {
        file => 'lib/Unicode/Truncate.pm',
      },
    },
    OBJECT => 'Truncate.o ',
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/Unicode-Truncate.git',
        bugtracker => 'https://github.com/hoytech/Unicode-Truncate/issues',
      },
      prereqs => {
        develop => {
          requires => {
            'Inline::C' => '0.72',
            'Inline::Module::LeanDist' => '0.32',
            'Inline::Filters::Ragel' => '0.101',
          },
        },
      },
    },
);

WriteMakefile(%args);
