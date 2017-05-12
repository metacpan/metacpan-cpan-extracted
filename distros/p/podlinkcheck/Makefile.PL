#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

# This file is part of PodLinkCheck.
#
# PodLinkCheck is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# PodLinkCheck is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %PREREQ_PM = ('constant::defer' => 0,
                 'File::Find::Iterator' => 0,
                 'File::HomeDir' => 0,
                 'File::Spec' => '0.8', # version 0.8 for ->devnull()
                 'File::Temp' => 0,
                 'IPC::Run' => 0,
                 'List::Util' => 0,
                 'Locale::TextDomain' => 0,
                 'Pod::Simple' => 0,
                 'Pod::Find' => 0,
                 'Search::Dict' => 0,
                );
my %TEST_REQUIRES = (
                     # for the t/*.t tests
                     'Test::More' => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME             => 'podlinkcheck',
   ABSTRACT         => 'Check POD L<> link references.',
   VERSION_FROM     => 'podlinkcheck',
   AUTHOR           => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE          => 'gpl_3',
   SIGN             => 1,
   EXE_FILES        => [ 'podlinkcheck' ],
   MIN_PERL_VERSION => '5.006',
   PREREQ_PM        => \%PREREQ_PM,
   TEST_REQUIRES    => \%TEST_REQUIRES,

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/podlinkcheck/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },

     # podlinkcheck gets the dist name
     provides =>
     { 'podlinkcheck' => { file => 'META.yml',
                           version => 15,
                         },
       'App::PodLinkCheck' =>
       { file => 'lib/App/PodLinkCheck.pm',
         version => 15,
       },
       'App::PodLinkCheck::ParseLinks' =>
       { file => 'lib/App/PodLinkCheck/ParseLinks.pm',
         version => 15,
       },
       'App::PodLinkCheck::ParseSections'
       => { file => 'lib/App/PodLinkCheck/ParseSections.pm',
            version => 15,
          },
     },

     prereqs =>
     { runtime =>
       { suggests =>
         { # think it's a little faster than the plain meta
          'CPAN::SQLite' => 0,
         },
         recommends =>
         { # nice sort order for filenames in tree traversal
          'Sort::Key::Natural' => 0,

          # Pod::Simple 3.24 has a fix for L<login.conf(5)> and similar
          # man-page links with a "." dot in the name
          'Pod::Simple' => '3.24',
         },
       },
     },

     optional_features =>
     { maximum_interoperation =>
       { description => 'Have maximum inter-operation with other modules (optional supported other stuff).',
         prereqs =>
         { runtime =>
           { requires => { 'CPAN::SQLite' => 0,
                           'CPANPLUS::Backend' => 0,
                           'CPANPLUS::Configure' => 0,
                           'Sort::Key::Natural' => 0,
                         },
           },
         },
       },
     },
   },
  );
