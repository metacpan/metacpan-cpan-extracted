#!/usr/bin/perl -w

# Copyright 2009, 2011, 2012, 2014, 2015 Kevin Ryde

# This file is part of constant-defer.
#
# constant-defer is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# constant-defer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with constant-defer.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME          => 'constant::defer',
   ABSTRACT      => 'Constant subs with deferred value calculation.',
   VERSION_FROM  => 'lib/constant/defer.pm',
   PREREQ_PM     => { vars => 0, },
   TEST_REQUIRES => { Test => 0,
                      # lib.pm is in the core but declare it here so
                      # Module::Mask::Deps knows it's needed
                      lib => 0,
                    },
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE       => 'gpl_3',
   SIGN          => 1,
   # probably anything
   MIN_PERL_VERSION => '5',

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     no_index    => { directory=>['devel','xt'] },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/constant-defer/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     prereqs =>
     { test =>
       { suggests =>
         { 'Scalar::Util' => 0,  # for weaken() checking
         }
       },
     },
   },
  );

exit 0;
