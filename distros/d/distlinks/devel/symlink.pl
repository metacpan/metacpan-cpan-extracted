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

use 5.006;
use strict;
use warnings;

use FindBin;
my $progfile = "$FindBin::Bin/$FindBin::Script";
print $progfile,"\n";

# uncomment this to run the ### lines
use Smart::Comments;

{
  system ('mkdir /tmp/distlinks');
  system ('ln -s nosuchfile /tmp/distlinks/foo.txt');
  system ('ln -s nosuchfile /tmp/distlinks/quux.txt');
  system ('touch /tmp/distlinks/bar.txt');
  # ### exists: -e '/tmp/.#foo.pm'
  # ### exists: -e '/tmp/nosuch'
  # ### exists: -e '/tmp/foo.pm'
  # ### exists: -e '/tmp/'
  # ### dir: -d '/tmp/.#foo.pm'
  # ### dir: -d '/tmp/nosuch'
  # ### dir: -d '/tmp/foo.pm'
  # ### dir: -d '/tmp/'
  require App::Distlinks;
  my $dl = App::Distlinks->new;
  @ARGV = ('--verbose=3','/tmp/distlinks','/etc/motd');
  $dl->command_line();
  exit 0;
}
 
