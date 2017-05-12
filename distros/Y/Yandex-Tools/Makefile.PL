#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $prereqs = {
  'Cwd'  => 0,
  'Storable'  => 0,
  'Time::HiRes'  => 0,
  'Time::Local'  => 0,
  'IPC::Cmd' => 0.84,
  };

if ($^O ne 'linux') {
  $prereqs->{'Proc::ProcessTable'} => 0;
}

WriteMakefile(
  NAME          => 'Yandex::Tools',
  VERSION_FROM  => 'lib/Yandex/Tools.pm',
  ABSTRACT_FROM => 'lib/Yandex/Tools.pm',
  PREREQ_PM     => $prereqs,
  AUTHOR        => 'Petya Kohts <petya@kohts.com>',
  );
