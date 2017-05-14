use 5.008005;
use ExtUtils::MakeMaker 7.12; # for XSMULTI option

WriteMakefile(
  NAME           => 'XS::Tutorial',
  VERSION_FROM   => 'lib/XS/Tutorial.pm',
  PREREQ_PM      => { 'Test::More' => 0, 'ExtUtils::MakeMaker' => '7.12' },
  ABSTRACT_FROM  => 'lib/XS/Tutorial.pm',
  AUTHOR         => 'David Farrell',
  CCFLAGS        => '-Wall -std=c99',
  OPTIMIZE       => '-O3',
  LICENSE        => 'freebsd',
  XSMULTI        => 1,
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/dnmfarrell/XS-Tutorial.git',
              web  => 'https://github.com/dnmfarrell/XS-Tutorial',
          },
      }})
   : ()
  ),
);
