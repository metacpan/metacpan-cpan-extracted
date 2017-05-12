#!/usr/bin/perl

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Tie-TZ',
   ABSTRACT     => 'Tied TZ env var calling tzset() when changed.',
   VERSION_FROM => 'lib/Tie/TZ.pm',
   MIN_PERL_VERSION => '5', # probably not really
   PREREQ_PM    => {
                    'constant'   => 0,
                    'File::Spec' => 0,
                    'FindBin'    => 0,
                    'Test::More' => 0,
                   },

   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/tie-tz/index.html' },

     recommends => {
                    'warnings' => 0,
                   },
   },
  );
