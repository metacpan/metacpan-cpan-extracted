#!/usr/bin/perl -w

# Copyright 2010, 2011, 2013 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use warnings;
use Test;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

my $test_count = (tests => 4)[1];
plan tests => $test_count;

if (! eval { require Encode }) {
  MyTestHelpers::diag ('Encode.pm module not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('No Encode module', 1, 1);
  }
  exit 0;
}

if (! eval { require Encode::HanExtra }) {
  MyTestHelpers::diag ('Encode::HanExtra not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('no Encode::HanExtra module', 1, 1);
  }
  exit 0;
}

sub to_hex {
  my ($str) = @_;
  return join (' ',
               map {sprintf("%02X", ord(substr($str,$_,1)))}
               0 .. length($str)-1);
}

require Encode::X11;

#------------------------------------------------------------------------------
# decode()

{
  foreach my $elem (
                    # cns11643-1 
                    [ [0x4E00], "\x1B\x24\x28\x47"."\x44\x21" ],
                    [ [0x4E00], "\x1B\x24\x29\x47"."\xC4\xA1" ],
                   ) {
    my ($aref, $bytes) = @$elem;
    my $name = sprintf("decode() %s", to_hex($bytes));

    my $bytes_left = $bytes;
    my $want = join('', map {chr} @$aref);
    my $got = Encode::decode('x11-compound-text', $bytes_left,
                             Encode::FB_QUIET());
    $bytes_left = to_hex($bytes_left);
    $got = to_hex($got);
    $want = to_hex($want);
    ok ($got, $want, $name);
    ok ($bytes_left, '', $name);
  }
}

#------------------------------------------------------------------------------
exit 0;
