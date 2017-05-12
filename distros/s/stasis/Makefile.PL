use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'stasis',
  VERSION_FROM  => 'stasis',
  ABSTRACT_FROM => 'stasis',
  AUTHOR        => 'David Farrell',
  LICENSE       => 'FreeBSD',
  EXE_FILES     => [qw(stasis)],
  PREREQ_PM     => {
      'autodie'       => 0,
      'Time::Piece'   => 0,
      'Time::Seconds' => 0,
      'Getopt::Long'  => 0,
      'Pod::Usage'    => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/dnmfarrell/Stasis.git',
              web  => 'https://github.com/dnmfarrell/Stasis',
          },
      }})
   : ()
  ),
);
