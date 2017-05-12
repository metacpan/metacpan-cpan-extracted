#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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



use lib 'devel/lib';
$ENV{'DISPLAY'} ||= ":0";




# Usage: perl xi-info.pl
#
# Print some information from the XInputExtension.
#

use 5.004;
use strict;
use X11::Protocol;

# uncomment this to run the ### lines
use Smart::Comments;

my $X = X11::Protocol->new;
if (! $X->init_extension('XInputExtension')) {
  print "No XInputExtension on the server\n";
  exit 0;
}

my ($major, $minor) = $X->XIGetExtensionVersion;
print "XInputExtension version $major.$minor\n";

my @infos = $X->XIListInputDevices;
### @infos

### atom 82: $X->GetAtomName(82)
### atom 83: $X->GetAtomName(83)


exit 0;

