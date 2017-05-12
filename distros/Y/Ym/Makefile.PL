#!/usr/bin/perl
use strict;
use 5.008008;
use ExtUtils::MakeMaker;

my $prereqs = {
  'Cwd'  => 0,
  'FindBin' => 0,
  'Storable'  => 0,
  'Data::Dumper' => 0,
  'File::Copy' => 0,
  };

WriteMakefile(
  NAME          => 'Ym',
  VERSION_FROM  => 'lib/Ym.pm',
  EXE_FILES     => [ 'bin/ym' ],
  PREREQ_PM     => $prereqs,
  AUTHOR     => 'Andrey Grunau <andrey-grunau@yandex.ru>',
  );

