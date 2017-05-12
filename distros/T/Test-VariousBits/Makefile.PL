#!/usr/bin/perl -w

# Copyright 2011, 2012, 2014, 2015 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.

require 5;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Test::VariousBits',
   ABSTRACT     => 'Various test helpers.',
   VERSION_FROM => 'lib/Test/Without/Shm.pm',
   PREREQ_PM    => {
                    'lib' => 0,
                    'vars' => 0,
                   },
   TEST_REQUIRES => {
                     'Test' => 0,
                    },
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   # probably anything
   MIN_PERL_VERSION => '5',

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     no_index    => { directory=>['devel','xt'] },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/test-variousbits/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },

     # Test::VariousBits gets the dist name, no actual module of that name
     provides =>
     { 'Test::VariousBits'       => { file => 'META.yml',
                                      version => 7,
                                    },
       'Module::Util::Masked'    => { file => 'lib/Module/Util/Masked.pm',
                                      version => 7,
                                    },
       'Test::Weaken::ExtraBits' => { file => 'lib/Test/Weaken/ExtraBits.pm',
                                      version => 7,
                                    },
       'Test::Without::GD'       => { file => 'lib/Test/Without/GD.pm',
                                      version => 7,
                                    },
       'Test::Without::Shm'      => { file => 'lib/Test/Without/Shm.pm',
                                      version => 7,
                                    },
     },

     prereqs =>
     { runtime =>
       { suggests =>
         { 'Sub::Delete' => 0,
         },
       },
       test =>
       { suggests =>
         {
          # have "make test" do as much as possible
          'IPC::SysV'             => 0,
          'Module::Util'          => 0,
          'Module::Mask'          => 0,
          'Test::Without::Module' => 0,
          'Scalar::Util'          => 0,
         },
       },
     },

     optional_features =>
     { maximum_interoperation =>
       { description => 'Have maximum inter-operation with other modules.',
         prereqs =>
         { runtime =>
           { requires =>
             { 'Sub::Delete' => 0,
             },
           },
         },
       },
     },
   },
  );
