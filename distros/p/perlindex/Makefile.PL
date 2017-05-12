#!/usr/bin/perl
#                              -*- Mode: Perl -*- 
# Author          : Ulrich Pfeifer
# Created On      : Tue May 27 17:27:28 1997
# Last Modified On: Mon Nov 17 19:47:45 2008
# Language        : CPerl
# Update Count    : 36
#
# (C) Copyright 1997-2005, Ulrich Pfeifer, all rights reserved.  This
# file is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

$VERSION = "1.606";

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'perlindex',
    'VERSION'      => $VERSION,
    'LIBS'         => [''],   # e.g., '-lm' 
    'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'          => '',     # e.g., '-I/usr/include/other' 
    'dist'         => { SUFFIX => "gz", COMPRESS => "gzip -f"},
# we do bundle that module in the distribution
#   'PREREQ_PM'    => { 'Text::English' => 0 },
    'EXE_FILES'    => [ 'perlindex' ],
    'clean'        => { 'FILES' => 'perlindex' },
);

