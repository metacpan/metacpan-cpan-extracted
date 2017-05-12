#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

use strict;
use App::Distlinks;
use File::Locate::Iterator;

my $distlinks = App::Distlinks->new
  (verbose => 0,
   only_local => 1);
my $fli = File::Locate::Iterator->new
  (regexp => qr{^/usr/share/doc/.*\.html?$});

   # (regexp => qr{^/usr/share/doc/aspell-doc/aspell-dev.html/Filter-Interface.html$});

   while (my $filename = $fli->next) {
     next unless -e $filename;
     next if -d $filename;
     $distlinks->check_dir_or_file($filename);
   }
   exit 0;
