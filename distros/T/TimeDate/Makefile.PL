# This -*- perl -*- script makes the Makefile

BEGIN { require 5.004 }

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME     => 'Date::Parse',
  DISTNAME => 'TimeDate',
  AUTHOR   => 'Graham Barr <gbarr@pobox.com>',
  VERSION_FROM => 'lib/Date/Parse.pm',
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
      META_MERGE => {
      resources => {
        bugtracker => {web => 'https://github.com/atoomic/perl-TimeDate/issues'},
        repository => {
          type => 'git',
          url  => 'https://github.com/atoomic/perl-TimeDate.git',
          web  => 'https://github.com/atoomic/perl-TimeDate',
        },
      }
    }
      )
    : ()
  ),
);
