#!perl -w

# Makefile.PL for Tie::CacheHash module  -*- perl -*-
# $Id: Makefile.PL,v 0.50 1999/8/17 10:00:00 jamie Exp $

use strict;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME		=> 'Tie::CacheHash',
    DISTNAME		=> 'Tie-CacheHash',
    VERSION_FROM	=> 'lib/Tie/CacheHash.pm',
    ABSTRACT_FROM	=> 'lib/Tie/CacheHash.pm',
    ($] >= 5.005 ?
      (
	AUTHOR		=> 'Jamie McCarthy (jamie@mccarthy.org)'
      )
      : ()
    ),
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }
);

