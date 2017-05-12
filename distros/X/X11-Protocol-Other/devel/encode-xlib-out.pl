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

use 5.004;
use strict;
use Encode;
use Encode::X11;
# use Encode::JP;

# uncomment this to run the ### lines
use Smart::Comments;

my @ords = grep { ! (($_ >= 0x80 && $_ <= 0x9F)
                     || ($_ >= 0xD800 && $_ <= 0xDFFF)
                     || ($_ >= 0xFDD0 && $_ <= 0xFDEF)
                     || ($_ >= 0xFFFE && $_ <= 0xFFFF)
                     || ($_ >= 0x1FFFE && $_ <= 0x1FFFF)) }
  32 .. 0x2FA1D;
my $ords_str = join ('', map {chr} @ords);


{
  my $chars = '';
  my $bytes = '';

  foreach my $i (@ords) {
    ### i: sprintf("0x%X",$i)
    my $chr = chr($i);
    my $input_chr = $chr;
    my $encode = Encode::encode('x11-compound-text', $input_chr,
                                Encode::FB_QUIET());
    if (length $input_chr) {
      MyTestHelpers::diag ("skip unencodable ",to_hex($chr));
      next;
    }

    $bytes .= $encode;
    $chars .= $chr;
  }

  {
    open my $fh, '> :encoding(utf-8)', 'devel/encode-xlib.utf8' or die;
    print $fh $chars or die;
    close $fh or die;
  }
}
exit 0;
