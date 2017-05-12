#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

my $test_count = 1;
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
# round trip

my @ords = grep { ! (($_ >= 0x7F && $_ <= 0x9F)
                     || ($_ >= 0xD800 && $_ <= 0xDFFF)
                     || ($_ >= 0xFDD0 && $_ <= 0xFDEF)
                     || ($_ >= 0xFFFE && $_ <= 0xFFFF)
                     || ($_ >= 0x1FFFE && $_ <= 0x1FFFF)) }
  32 .. 0x2FA1D;
#  32 .. 0x203E;
MyTestHelpers::diag("encode-decode exercise ",scalar(@ords)," many ords");

{
  my $good = 1;
  my $count = 0;
  foreach my $i (@ords) {
    my $chr = chr($i);
    my $input_chr = $chr;
    my $bytes = Encode::encode('x11-compound-text', $input_chr,
                               Encode::FB_QUIET());
    if (length $input_chr) {
      # diag "skip unencodable ",to_hex($chr);
      next;
    }
    $count++;

    my $bytes_left = $bytes;
    my $decode = Encode::decode('x11-compound-text', $bytes_left,
                                Encode::FB_QUIET());
    if ($bytes_left) {
      MyTestHelpers::diag (sprintf "U+%04X decode remaining bytes: %s\n", $i, to_hex($bytes_left));
      $good = 0;
    }
    if ($decode ne $chr) {
      MyTestHelpers::diag (sprintf "U+%04X decode got %s want %s",
                           $i, to_hex($decode), to_hex($chr));
      MyTestHelpers::diag (sprintf "  encode bytes [len %d]  %s",
                           length($bytes), to_hex($bytes));
      $good = 0;
      exit 1;
    }
  }
  MyTestHelpers::diag ("total count ", $count);
  ok ($good);
}

exit 0;
