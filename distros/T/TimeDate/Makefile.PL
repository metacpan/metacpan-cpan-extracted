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
  META_MERGE => {
      resources => {
        bugtracker => 'https://github.com/atoomic/perl-TimeDate/issues',
        repository => 'https://github.com/atoomic/perl-TimeDate',
      }
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
);
