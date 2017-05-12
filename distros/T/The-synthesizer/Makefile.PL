use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'The::synthesizer',
  AUTHOR => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  VERSION_FROM => 'lib/The/synthesizer.pm',
  PREREQ_PM => {},
  test => { TESTS => 't/*.t' }
);
