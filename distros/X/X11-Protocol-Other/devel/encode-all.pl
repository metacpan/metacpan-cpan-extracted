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

use 5.008;
use strict;
use Encode;
use FindBin;
use File::Slurp;

my $dir = $FindBin::Bin;
my $filename = "$dir/encode-all.utf8";

my @ords = grep { ! (($_ >= 0x7F && $_ <= 0x9F)
                     || ($_ >= 0xD800 && $_ <= 0xDFFF)
                     || ($_ >= 0xFDD0 && $_ <= 0xFDEF)
                     || ($_ >= 0xFFFE && $_ <= 0xFFFF)
                     || ($_ >= 0x1FFFE && $_ <= 0x1FFFF)) }
  32 .. 0x2FA1D;
printf "ords len %d\n", scalar(@ords);

my $str = join ('', map {chr} @ords);
print "str len ",length($str),"\n";

File::Slurp::write_file($filename,
                        { binmode  => ':encoding(utf-8)',
                          err_mode => 'croak' },
                        $str);
print "file len ",-s $filename,"\n";

my $read = File::Slurp::read_file('devel/encode-all.utf8',
                                  {binmode=>':utf8'});
print "read len ",length($read),"\n";



exit 0;
