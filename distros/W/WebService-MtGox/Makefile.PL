use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'WebService::MtGox',
  AUTHOR        => 'John BEPPU <beppu@cpan.org>',
  LICENSE       => 'perl',
  VERSION_FROM  => 'lib/WebService/MtGox.pm',
  ABSTRACT_FROM => 'lib/WebService/MtGox.pm',
  EXE_FILES     => ['bin/mg'],
  PREREQ_PM     => {
    'Moo'                  => 0,
    'Ouch'                 => 0,
    'parent'               => 0,
    'JSON'                 => 0,
    'LWP::UserAgent'       => 0,
    'LWP::Protocol::https' => 0,
    'Try::Tiny'            => 0,
    'Data::Dump'           => 0,
    'Getopt::Long'         => 0,
    'Test::More'           => 0,
  }
);
