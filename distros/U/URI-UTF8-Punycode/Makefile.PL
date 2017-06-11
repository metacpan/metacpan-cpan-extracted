use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'URI::UTF8::Punycode',
  ABSTRACT_FROM => 'lib/URI/UTF8/Punycode.pm',
  AUTHOR        => 'Twinkle Computing <twinkle@cpan.org>',
  LICENSE       => 'GPL_3',
  VERSION_FROM  => 'lib/URI/UTF8/Punycode.pm',
  EXE_FILES     => ['script/puny'],
);
