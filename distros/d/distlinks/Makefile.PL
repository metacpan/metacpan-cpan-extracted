#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013, 2014 Kevin Ryde

# This file is part of Distlinks.
#
# Distlinks is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'distlinks',
   ABSTRACT     => 'URL link checking with database.',
   VERSION_FROM => 'distlinks',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   EXE_FILES    => [ 'distlinks' ],
   MIN_PERL_VERSION => '5.010',

   PREREQ_PM    => {
                    'Archive::Zip' => 0,
                    'Class::Singleton' => 0,
                    'constant::defer' => 0,

                    'DBI' => 0,
                    'DBD::SQLite' => 0,

                    'File::chdir' => 0,
                    'File::Find::Iterator' => 0,
                    'File::HomeDir' => 0,
                    'File::Type' => 0,
                    'HTML::Entities' => 0,
                    'HTML::Parser' => 0,
                    'Image::ExifTool' => 0,
                    'IO::String'           => 0,
                    'Iterator::Simple' => 0,
                    'List::MoreUtils' => '0.24', # 0.24 for stack growing, maybe
                    'Locale::TextDomain' => 0,
                    'Module::Util' => 0,
                    'Perl6::Slurp' => 0,

                    # LWP 5.818 for dump(), and 5.819 for bug fixes
                    'LWP'        => 5.819,
                    'LWP::Debug' => 0,
                    'URI'        => 0,
                    'HTTP::Response' => 0,
                    'HTTP::Status' => 0,
                    'HTTP::Date' => 0,

                    'Regexp::Common' => 0,
                    'Regexp::Common::URI::RFC2396' => 0,

                    'URI::file' => 0,
                    'URI::Escape' => 0,
                    'URI::Find' => 0,
                    'WWW::Mechanize' => 0,
                    'YAML' => 0,

                   },

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/distlinks/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },
   },
  );
