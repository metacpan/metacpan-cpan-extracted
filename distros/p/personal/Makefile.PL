
use 5.006_001;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'personal',
  VERSION_FROM   => 'lib/personal.pm',
  ABSTRACT_FROM  => 'lib/personal.pm',
  AUTHOR         => 'Andrian Zubko aka Ondr, <ondr@cpan.org>'
);
