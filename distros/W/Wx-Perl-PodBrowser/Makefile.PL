#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2017 Kevin Ryde

# This file is part of Wx-Perl-PodBrowser.
#
# Wx-Perl-PodBrowser is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Wx-Perl-PodBrowser is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Wx-Perl-PodBrowser.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Wx::Perl::PodBrowser',
   ABSTRACT     => 'POD browser in Wx using wxRichTextCtrl.',
   VERSION_FROM => 'lib/Wx/Perl/PodBrowser.pm',
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008',
   EXE_FILES    => [ 'wx-perl-podbrowser' ],
   PREREQ_PM    => {
                    'Pod::Simple' => 0, # included in with perl 5.10 too
                    'Wx' => 0,
                    'Wx::RichText' => 0,
                   },
   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/wx-perl-podbrowser/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     recommends =>
     { 'Software::License::GPL_3' => 0,

       # Pod::Simple version 3.27 fixes an =encoding put through to the
       # output in a few prior versions.
       'Pod::Simple' => 3.27,
     },
     no_index => { directory=>['devel','xt'] },

     prereqs =>
     { test =>
       { suggests =>
         { 'Test::Weaken' => 3, # version 3 for "contents"
         },
       },
     },
     optional_features =>
     {
      maximum_interoperation =>
      { description => 'All the optional things with and for Wx-Perl-PodBrowser.',
        requires => {
                     'Software::License::GPL_3' => 0,
                     'Wx::Demo' => 0,
                    },
      },
     },
   },
  );
