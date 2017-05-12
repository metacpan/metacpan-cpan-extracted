#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Test-VariousBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.

require 5;
use strict;

# uncomment this to run the ### lines
use Devel::Comments;

{
  require Test::Weaken;
  require Test::Weaken::ExtraBits;
  my $two;
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         open my $fh, '>/dev/null';
         open $two, '>&', $fh;

         my $global;
         $global = *{$fh}{IO};
         $two = *{$fh}{IO};
         # Scalar::Util::weaken($global);
         print "one IO $global\n";
         print "two IO $two\n";
         return \$fh;
       },
       #contents => \&Test::Weaken::ExtraBits::contents_glob_IO,
       tracked_types => ['IO'],
     });
  # print "global $global\n";
  print "two IO $two\n";
  print "leaks ",($leaks||'none'),"\n";
  exit 0;
}
{
  my $ref = \*STDOUT;
  print *STDOUT{FILEHANDLE},"\n";
  print *STDOUT{IO},"\n";
  exit 0;
}
