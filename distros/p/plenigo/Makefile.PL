use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'plenigo',
  VERSION_FROM     => 'lib/Meta.pm',
  ABSTRACT_FROM    => 'lib/Meta.pm',
  AUTHOR           => 'plenigo GmbH',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.010',
  PREREQ_PM        => {
    'strict'   => 1,
    'warnings' => 1,
    'JSON' => '2.97001',
    'REST::Client' => '273',
    'Crypt::JWT' => '0.022',
    'Moo' => '2.003004',
    'Data::UUID' => '1.221',
    'Carp::Always' => '0.13',
    'Throwable' => '0.200013',
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/plenigo/plenigo_php_sdk.git',
              web  => 'https://github.com/plenigo/plenigo_php_sdk',
          },
      }})
   : ()
  ),
);
