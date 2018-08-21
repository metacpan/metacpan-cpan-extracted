use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Weather::Fetch',
  VERSION_FROM     => 'lib/Weather/Fetch.pm',
  ABSTRACT_FROM    => 'lib/Weather/Fetch.pm',
  AUTHOR           => 'Brad Heffernan',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['script/weather.pl'],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'XML::LibXML' => '1.0',
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/BradHeff/Weather.git',
              web  => 'https://github.com/BradHeff/Weather',
          },
      }})
   : ()
  ),
);