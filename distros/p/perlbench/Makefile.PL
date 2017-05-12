# This is really only used to make a distribution file.

use ExtUtils::MakeMaker;

WriteMakefile (
   NAME => 'perlbench',
   VERSION_FROM => 'lib/PerlBench.pm',
   EXE_FILES => [qw(perlbench-timeit)],
   PREREQ_PM => {
      'Time::HiRes' => 0,
   },
   dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
