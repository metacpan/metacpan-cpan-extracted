#!/usr/bin/perl
use strict;
use ExtUtils::MakeMaker;

my $prereqs = {
  'DBI'  => 0,
  'Data::Dumper'  => 0,
  'Yandex::Tools'  => 0,
  };

WriteMakefile(
  NAME          => 'mmmf',
  VERSION_FROM  => 'lib/mmmf.pm',
  ABSTRACT_FROM => 'lib/mmmf.pm',
  EXE_FILES     => [ 'mmmf' ],
  PREREQ_PM     => $prereqs,
  AUTHOR     => 'Petya Kohts <petya@kohts.ru>',
  );
