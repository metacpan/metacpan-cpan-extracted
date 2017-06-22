use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'Twitter::Queue',
  VERSION_FROM   => 'lib/Twitter/Queue.pm',
  PREREQ_PM      => { 'Test::More' => 0, 'Net::Twitter::Lite' => 0 },
  ABSTRACT_FROM  => 'lib/Twitter/Queue.pm',
  AUTHOR         => 'David Farrell',
  LICENSE        => 'freebsd',
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/dnmfarrell/Twitter-Queue.git',
              web  => 'https://github.com/dnmfarrell/Twitter-Queue',
          },
      }})
   : ()
  ),
);
