#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2017 Kevin Ryde

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

my $test_count = (tests => 30)[1];
plan tests => $test_count;

if (! eval { require Encode }) {
  MyTestHelpers::diag ('Encode.pm module not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('No Encode module', 1, 1);
  }
  exit 0;
}

require Encode::X11;

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 31;
  ok ($Encode::X11::VERSION, $want_version, 'VERSION variable');
  ok (Encode::X11->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Encode::X11->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Encode::X11->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

sub to_hex {
  my ($str) = @_;
  return join (' ',
               map {sprintf("%02X", ord(substr($str,$_,1)))}
               0 .. length($str)-1);
}

#------------------------------------------------------------------------------
# decode()

{
  foreach my $elem (
                    # jis201 0x7E "overline"
                    [ [0x203E], "\x1B\x28\x4A\x7E" ],

                    # utf-8 and back to latin-1
                    [ [0xAA,0xC2,0xAA],
                      "\x1B\x25\x47\xC2\xAA\x1B\x25\x40\xC2\xAA" ],

                    # utf-8 and back to jis201 GR
                    [ [0xAA,0xFF61],
                      "\x1B\x29\x49"
                      . "\x1B\x25\x47"
                      . "\xC2\xAA"
                      . "\x1B\x25\x40"
                      . "\xA1" ],

                    # jis201
                    [ [0xFF61], "\x1B\x29\x49\xA1" ],

                    # jis201 left
                    [ [0xA2], "\x1B\x29\x4A\xA2" ],

                    # gb2312 high
                    [ [0x2C9], "\x1B\x24\x29\x41\xA1\xA5" ],

                    # gb2312 low
                    [ [0x2C9], "\x1B\x24\x28\x41\x21\x25" ],

                    [ [0x41], "\x41" ],



                    # emacs ipa
                    # [ [0x25B], "\x1B\x2D\x30\xA3" ],

                    # emacs 0x30 chinese-big5-1
                    # [ [0x2574], "\x1B\x24\x28\x30\x21\x3B" ],
                    # [ [0x2CD], "\x1B\x24\x28\x30\x22\x26" ],

                    # emacs 0x31 chinese-big5-2
                    # [ [0x2593], "\x1B\x24\x2D\x31\x72\x6F" ],

                    # [ [0x114], "\x1B\x24\x2D\x31\xA0\xB4" ],  # ??

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
# encode()

{
  foreach my $elem (
                    [ [0x277], "1B 25 47 C9 B7 1B 25 40" ],

                    [ [0x203E], "1B 28 4A 7E" ],
                    [ [0x7E],   "7E" ],

                    # jis201
                    [ [0xFF61], "1B 29 49 A1" ],
                    [ [0xFF62], "1B 29 49 A2" ],

                   ) {
    my ($chars_aref, $want) = @$elem;
    my $chars = join('', map {chr} @$chars_aref);
    my $chars_left = $chars;
    my $name = sprintf("encode() %s", to_hex($chars));

    my $got = Encode::encode('x11-compound-text', $chars_left,
                             Encode::FB_QUIET());
    $chars_left = to_hex($chars_left);
    $got = to_hex($got);
    ok ($got, $want, $name);
    ok ($chars_left, '', $name);
  }
}

#------------------------------------------------------------------------------

exit 0;
