#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2014, 2015, 2017 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use ExtUtils::MakeMaker;

my %encode_modules =
  (
   # 1.00 for ksc5601-raw, probably
   'Encode'           => 1.00,
   'Encode::HanExtra' => 0.06,  # 0.06 for cns11643-*

   # these come with Encode anyway ...
   # 'Encode::Byte'     => 0,     # for iso-8859-2 etc
   # 'Encode::JP'       => 0,     # for jis0201-raw
  );

WriteMakefile
  (NAME          => 'X11::Protocol::Other',
   ABSTRACT      => 'Miscellaneous helpers for X11::Protocol connections.',
   VERSION_FROM  => 'lib/X11/Protocol/Other.pm',
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE       => 'gpl_3',
   SIGN          => 1,
   PREREQ_PM     => {
                     'X11::Protocol' => 0,
                    },
   TEST_REQUIRES => {
                     'Test' => 0,
                    },
   MIN_PERL_VERSION => '5.004',

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     no_index    => { directory=>['devel','xt'] },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/x11-protocol-other/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },

     prereqs =>
     { test =>
       { suggests =>
         {
          # have "make test" do as much as possible
          'Module::Util' => 0, # checking for HanExtra
          %encode_modules,
         }
       },
     },

     optional_features =>
     { maximum_interoperation =>
       { description => 'All the optional things which may be used.',
         prereqs =>
         { runtime =>
           { requires =>
             { %encode_modules },
           },
         },
       },
     },
   },
  );

# MyMakeMakerExtras_Pod_Coverage => [ 'X11::Protocol::Other',
#                                     'X11::Protocol::GrabServer',
#                                     'X11::Protocol::WM',
#                                   ],
