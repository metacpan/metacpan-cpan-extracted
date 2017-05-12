
use strict;
use warnings;

 BEGIN { require 5.010; } 

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Tk-Action',
  NAME      => 'Tk::Action',
  AUTHOR    => "Jerome\ Quelin",
  ABSTRACT  => "action\ abstraction\ for\ tk",
  VERSION   => '1.093390',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "MooseX::Has::Sugar" => '0',
    "English" => '0',
    "Test::More" => '0',
    "File::Find" => '0',
    "Tk::Sugar" => '0',
    "MooseX::SemiAffordanceAccessor" => '0',
    "Moose" => '0.92',
  },
  test => {TESTS => 't/*.t'}
);

