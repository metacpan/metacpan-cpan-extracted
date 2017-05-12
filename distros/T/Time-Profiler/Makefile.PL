use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Time::Profiler',
  VERSION_FROM    => 'lib/Time/Profiler.pm',
# test            => { TESTS => 't/*.pl' },
  META_MERGE      => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/cade-vs/perl-time-profiler.git',
        web  => 'https://github.com/cade-vs/perl-time-profiler',
      },
    },
  },
);
