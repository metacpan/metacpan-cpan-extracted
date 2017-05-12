
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Value-Canary',
  NAME      => 'Value::Canary',
  AUTHOR    => "Florian\ Ragwitz\ \<rafl\@debian\.org\>",
  ABSTRACT  => "Callbacks\ for\ value\ destruction",
  VERSION   => '0.01',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "namespace::clean" => '0',
    "Sub::Exporter" => '0',
    "Variable::Magic" => '0',
    "Carp" => '0',
  },
  test => {TESTS => 't/*.t'}
);

