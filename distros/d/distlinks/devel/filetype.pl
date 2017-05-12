#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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


# MMagic doesn't recognise executables from their magic numbers.

use strict;
use warnings;
use File::Type;
use File::MMagic;
use Perl6::Slurp;

my $ft = File::Type->new;
my $mm = new File::MMagic;

foreach my $filename ("/usr/share/locale/de/LC_MESSAGES/asunder.mo",
                      "$ENV{HOME}/ch"."art/samples/kex/BRO03.exe",
                      "$ENV{HOME}/.cpan/source/authors/01mailrc.txt.gz",
                      "$ENV{HOME}/perl/hash-moreutils/Hash-Mogrify-0.03.tar.gz",
                      "/bin/cat",
                      "t/bom-utf16le.txt",
                      "/so/xtide/libtcd-2.2.2.tar.bz2",
                      "$ENV{HOME}/p/el/devel/d-perl-pod-preview.tar",
                     ) {
  print "\n$filename\n";
  print "  File::Type   ",$ft->checktype_filename($filename),"\n";
  print "  File::MMagic ",$mm->checktype_filename($filename),"\n";

  my $content = Perl6::Slurp::slurp ($filename);
  print "  by content\n";
  print "  File::Type   ",$ft->checktype_contents($content),"\n";
  print "  File::MMagic ",$mm->checktype_contents($content),"\n";
}

exit 0;
