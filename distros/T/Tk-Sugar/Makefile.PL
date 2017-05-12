
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Tk-Sugar',
  NAME      => 'Tk::Sugar',
  AUTHOR    => "Jerome\ Quelin",
  ABSTRACT  => "Sugar\ syntax\ for\ Tk",
  VERSION   => '1.093190',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "perl" => '5.008',
    "Test::More" => '0',
    "English" => '0',
    "File::Find" => '0',
    "Sub::Exporter" => '0',
  },
  test => {TESTS => 't/*.t'}
);

