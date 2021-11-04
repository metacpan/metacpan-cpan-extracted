#!/usr/bin/perl

use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'uHTML',
  ABSTRACT         => 'User specific extension of HTML code',
#   ABSTRACT_FROM    => 'uHTML.pm',
  VERSION          => '1.09',
#   VERSION_FROM     => 'uHTML.pm',
  AUTHOR           => [ 'Roland Mosler', 'uHTML@Place.Ug' ] ,
  LICENSE          => 'lgpl_3_0',
  MIN_PERL_VERSION => '5.018001',
  PREREQ_PM        => {
                        'strict'          => 0,
                        'version'         => 0,
                        'POSIX'           => 0,
                        'Exporter'        => 0,
                        'IO::Handle'      => 0,
                        'Time::Local'     => 0,
                        'LWP::MediaTypes' => 0,
                        'URI::Escape'     => 0,
                      },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {

      }})
   : ()
  ),
);