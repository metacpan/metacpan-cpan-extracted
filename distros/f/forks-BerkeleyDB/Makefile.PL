#!/usr/bin/perl -w
use ExtUtils::MakeMaker;
eval "use Devel::Required";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
 NAME		=> "forks::BerkeleyDB",
 AUTHOR		=> 'Eric Rybski (rybskej@yahoo.com)',
 ABSTRACT	=> 'High performance drop-in replacement for threads',
 VERSION_FROM	=> 'lib/forks/BerkeleyDB.pm',
 PREREQ_PM	=> {
  'forks' => 0.29,
  'Storable' => 0,
  'BerkeleyDB' => 0.27,
  'Tie::Restore' => 0.11,
  'Devel::Required' => 0.07
 },
 (MM->can('signature_target') ? (SIGN => 1) : ()),
);