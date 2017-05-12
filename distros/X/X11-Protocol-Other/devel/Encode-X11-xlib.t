#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.


# Check that emacs decodes the Encode::X11 output successfully.

use 5.004;
use strict;
use warnings;
use Test;
use FindBin;
use File::Spec;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

my $test_count = (tests => 3)[1];
plan tests => $test_count;

if (! eval { require Encode }) {
  MyTestHelpers::diag ('Encode.pm module not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('No Encode module', 1, 1);
  }
  exit 0;
}

require Encode::X11;

sub to_hex {
  my ($str) = @_;
  return join (' ',
               map {sprintf("%02X", ord(substr($str,$_,1)))}
               0 .. length($str)-1);
}

#------------------------------------------------------------------------------

my @ords = grep { ! (($_ >= 0x7F && $_ <= 0x9F)
                     || ($_ >= 0xD800 && $_ <= 0xDFFF)
                     || ($_ >= 0xFDD0 && $_ <= 0xFDEF)
                     || ($_ >= 0xFFFE && $_ <= 0xFFFF)
                     || ($_ >= 0x1FFFE && $_ <= 0x1FFFF)) }
#  32 .. 0x2FA1D;
  32 .. 0x2FA1;

{
  open my $fh, '>', 'tempfile.txt' or die;

  foreach my $i (@ords) {
    my $chr = chr($i);
    my $input_chr = $chr;
    my $encode = Encode::encode('x11-compound-text', $input_chr,
                                Encode::FB_QUIET());
    if (length $input_chr) {
      # diag "skip unencodable ",to_hex($chr);
      next;
    }

    printf $fh "0x%04X %s\n", $i, to_hex($encode)
      or die;

    $input_chr = $chr;
    my $utf8 = Encode::encode('utf-8', $input_chr, Encode::FB_QUIET());
    die if length $input_chr;
    printf $fh "%s\n", to_hex($utf8)
      or die;
  }

  close $fh or die;
}

exit 0;
