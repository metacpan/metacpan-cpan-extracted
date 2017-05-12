use ExtUtils::MakeMaker;


WriteMakefile (
  NAME => 'perlconsole',
  VERSION_FROM => 'lib/PerlConsole.pm',
  EXE_FILES => ['perlconsole'],
  PREREQ_PM => {
    'Term::ReadLine'       => 0,
    'B::Keywords'          => 0,
    'Module::Refresh'      => 0,
    'Lexical::Persistence' => 0},
);
