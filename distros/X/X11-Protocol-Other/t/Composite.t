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

BEGIN { require 5 }
use strict;
use X11::Protocol;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = (tests => 2)[1];
plan tests => $test_count;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ('Cannot connect to X server -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Cannot connect to X server', 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

{
  my ($major_opcode, $first_event, $first_error)
    = $X->QueryExtension('Composite');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no Composite on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("Composite extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('Composite')) {
  die "QueryExtension says Composite avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# CompositeQueryVersion

{
  my $client_major = 0;
  my $client_minor = 3;
  my @ret = $X->CompositeQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("server Composite version ", join('.',@ret));
  ok (scalar(@ret), 2);
  ok ($ret[0] <= $client_major, 1);

  # The X.org server circa 1.10 will return a higher minor version, not sure
  # if the spec is supposed to allow that, but don't worry about the test.
  #  ok ($ret[0] < $client_major
  #     || ($ret[0] == $client_major && $ret[1] <= $client_minor),
  #     1);
}

#------------------------------------------------------------------------------

exit 0;
