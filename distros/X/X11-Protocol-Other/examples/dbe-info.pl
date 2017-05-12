#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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


# Usage: perl dbe-info.pl
#
# Print some info from the DOUBLE-BUFFER extension.
#

use 5.004;
use strict;
use X11::Protocol;

my $X = X11::Protocol->new;
if (! $X->init_extension('DOUBLE-BUFFER')) {
  print "DOUBLE-BUFFER not available on the server\n";
  exit 0;
}

my ($major, $minor) = $X->DbeGetVersion (1,0);
print "DOUBLE-BUFFER extension version $major.$minor\n";

# Check just the default screen, by giving the $X->{'root'} window
#
my $root_visual = $X->root_visual;
my ($info_aref) = $X->DbeGetVisualInfo ($X->root);
my %hash = @$info_aref;
print "Default screen root visual $root_visual ",
  ($hash{$root_visual} ? "has" : "doesn't have"),
  " double buffering\n";

# Print info about all screens, by passing no drawables to DbeGetVisualInfo().
#
my @info_aref_list = $X->DbeGetVisualInfo;
foreach my $screen (0 .. $#info_aref_list) {
  print "Screen number $screen\n";
  my $info_aref = $info_aref_list[$screen];

  for (my $i = 0; $i < @$info_aref; ) {
    my $visual_id = $info_aref->[$i++];
    my $dp_aref = $info_aref->[$i++];

    my ($depth, $perflevel) = @$dp_aref;
    print "  visual $visual_id    depth $depth performance $perflevel\n";
  }
}

exit 0;
