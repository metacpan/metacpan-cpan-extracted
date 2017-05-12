#!/usr/bin/perl -w

# Copyright 2011, 2014 Kevin Ryde

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
  foreach my $i (
                  0x80 .. 0xFF
                ) {
    my $chr = chr($i);
    # my $bytes = Encode::encode('utf-8', $chr, Encode::FB_QUIET());
    my $bytes = Encode::encode('x11-compound-text', $chr, Encode::FB_QUIET());
    next if length $chr;
    printf "U+%04X = %s\n", $i, bytestr($bytes);
  }
  exit 0;
}

{
  @ords = (0x2022);
  foreach my $i (@ords) {
    my $chr = chr($i);
    # my $bytes = Encode::encode('jis0201-raw', $chr, Encode::FB_QUIET());
    my $bytes = Encode::encode('x11-compound-text', $chr, Encode::FB_QUIET());
    next if length $chr;
    printf "U+%04X = %s\n", $i, bytestr($bytes);
  }
  exit 0;
}

{
  # round trip
  @ords = (0x20AC); #  euro sign

  foreach my $i (@ords) {
    my $chr = chr($i);
    my $input_chr = $chr;
    my $bytes = Encode::encode('x11-compound-text', $input_chr,
                               Encode::FB_QUIET());
    next if length $chr;
    my $input_bytes = $bytes;
    my $decode = Encode::decode('x11-compound-text', $input_bytes,
                                Encode::FB_QUIET());
    if ($input_bytes) {
      printf "U+%04X remaining bytes: %s\n", $i, bytestr($input_bytes);
    }
    if ($decode ne $chr) {
      printf "U+%04X got %s want %s\n", $i, bytestr($decode), bytestr($chr);
    }
  }
  exit 0;
}
{
  foreach my $i (0x0 .. 0xFF) {
    my $bytes = chr($i);
    my $chars = Encode::decode ('jis0201-raw', $bytes, Encode::FB_QUIET());
    if (! $bytes) {
      my $u = ord($chars);
      my $chars_left = $chars;
      $bytes = Encode::encode ('jis0201-raw', $chars_left, Encode::FB_QUIET());
      printf "%02X %02X  %s\n", $i, $u, bytestr($bytes);
    }
  }
  exit 0;
}

{
  my $bytes = "\xA0\xB4";
  # $bytes = "\x20\x34";
  $bytes = "\x21\x25";
  my $ret = Encode::decode ('gb2312-raw', $bytes,  Encode::FB_QUIET());
  print "ret  ",bytestr($ret),"\n";
  print "left ",bytestr($bytes),"\n";
  exit 0;
}
{
  require File::Slurp;
  printf "ords len %d\n", scalar(@ords);

  foreach my $utf8name ('devel/encode-emacs23.ctext',
                        # <devel/encode*.utf8>
                       ) {
    (my $ctextname = $utf8name) =~ s/utf8$/ctext/;

    print "$ctextname len ",-s $ctextname,"\n";
    my $chars = File::Slurp::read_file($utf8name, {binmode=>':utf8'});
    printf "  chars %d\n", length($chars);

    my $bytes = File::Slurp::read_file($ctextname, {binmode=>':raw'});
    print "  bytes ",length($bytes),"\n";
    my $left = $bytes;
    my $decode = Encode::decode('x11-compound-text', $left, Encode::FB_QUIET());
    printf "  decode %d  bytes left %d\n", length($decode), length($left);
    my $upto = length($bytes) - length($left);
    printf "  upto 0x%X\n", $upto;
    print "  ",bytestr(substr($bytes,$upto-3,10)),"\n";
    print "  last decode ",bytestr(substr($decode,-5)),"\n";

    if ($chars ne $decode) {
      printf "  different lens want %d got %d\n", length($chars), length($decode);
    }

    print "\n";
  }
  exit 0;
}





{
  require X11::Protocol::Splash;
  foreach my $ord (0x401 .. 0x4001) {
    my $input = chr($ord);
    my $bytes = X11::Protocol::Splash->_encode_compound ($input, 1);
    if (! length $bytes) {
      next;
    }
    my $dec = X11::Protocol::Splash->_decode_compound ($bytes, 1);
    if ($dec ne chr($ord)) {
      printf "ord %02X\n", $ord;
      print "bytes ", length($bytes),": ";
      foreach my $i (0 .. length($bytes)-1) {
        printf " %02X", ord(substr($bytes,$i,1));
      }
      print "\n";
      print "remainder ",length($input),": ";
      foreach my $i (0 .. length($input)-1) {
        printf " %02X", ord(substr($input,$i,1));
      }
      print "\n";
      print "dec ", length($dec),": ";
      foreach my $i (0 .. length($dec)-1) {
        printf " %02X", ord(substr($dec,$i,1));
      }
      print "\n";
    }
  }
  exit 0;
}

{
  open my $out, '>:utf8', '/tmp/x.utf8' or die;
  foreach my $i (32 .. 0x2FA1D) {
    next if $i >= 0x80 && $i <= 0x9F;
    next if $i >= 0xD800 && $i <= 0xDFFF;
    next if $i >= 0xFDD0 && $i <= 0xFDEF;
    next if $i >= 0xFFFE && $i <= 0xFFFF;
    next if $i >= 0x1FFFE && $i <= 0x1FFFF;
    printf $out "U+%04X = %s\n", $i, chr($i);
  }
  close $out or die;
  exit 0;
}

{
  require X11::Protocol::Splash;
  my $input = "\x{2572}"; # wo
  $input = "\x{391}"; # capital alpha
  $input = "\x{6708}"; # month
  # my $bytes = Encode::encode ('iso-2022-jp', $input);
  my $bytes = X11::Protocol::Splash->_encode_compound ($input);
  print "remainder ",length($input),"\n";
  foreach my $i (0 .. length($input)-1) {
    printf " %02X", ord(substr($input,$i,1));
  }
  print "\n";
  print "bytes ", length($bytes),"\n";
  foreach my $i (0 .. length($bytes)-1) {
    printf " %02X", ord(substr($bytes,$i,1));
  }
  print "\n";
  exit 0;
}

{
  require X11::Protocol;
  require X11::Protocol::Splash;
  my $X = X11::Protocol->new;
  my $input = "\x{2572}"; # wo
  $input = "\x{391}"; # capital alpha
  $input = "\x{6708}"; # month
  $input = "\x{0401}\x{1234}\x{0401}";
  # my $bytes = Encode::encode ('iso-2022-jp', $input);
  my ($atom, @chunks) = X11::Protocol::Splash::_str_to_text_chunks($X,$input);
  print $X->atom_name($atom),"\n";
  foreach my $bytes (@chunks) {
    print "bytes ", length($bytes),"\n";
    foreach my $i (0 .. length($bytes)-1) {
      printf " %02X", ord(substr($bytes,$i,1));
    }
    print "\n";
  }
  exit 0;
}

{
  require Encode;
  require Encode::KR;
  require Encode::KR::2022_KR;
  my $input;
  $input = "\x{0401}";
  $input = "\x{391}"; # capital alpha
  $input = "\x{1234}";
  $input = "\x{0401}\x{1234}\x{0401}";
  my $bytes = Encode::encode (
                              'iso-2022-kr',
                              $input,
                              # Encode::FB_DEFAULT(),
                              Encode::FB_QUIET(),
                             );
  print "remainder ",length($input),"\n";
  foreach my $i (0 .. length($input)-1) {
    printf " %02X", ord(substr($input,$i,1));
  }
  print "\n";
  print "bytes ", length($bytes),"\n";
  foreach my $i (0 .. length($bytes)-1) {
    printf " %02X", ord(substr($bytes,$i,1));
  }
  print "\n";
  exit 0;
}
{
  require Set::IntSpan::Fast;
  require X11::Protocol::Splash;
  my $span = Set::IntSpan::Fast->new;
  my $prev = 0;
  # foreach my $i (32 .. 0x1000) {
  foreach my $i (32 .. 0x2FA1D) {
    next if $i >= 0xD800 && $i <= 0xDFFF;
    next if $i >= 0xFDD0 && $i <= 0xFDEF;
    next if $i >= 0xFFFE && $i <= 0xFFFF;
    next if $i >= 0x1FFFE && $i <= 0x1FFFF;
    my $str = chr($i);
    # X11::Protocol::Splash->_encode_compound ($str, 1);
    Encode::encode ('euc-kr', $str, Encode::FB_QUIET());
    if (! length($str)) {
      $span->add($i);
      if ($i != $prev+1) {
        print "$i\n";
      }
      $prev = $i;
    }
  }
  print $span->as_string,"\n";
  print "count ",$span->cardinality,"\n";
  exit 0;
}


{
  require POSIX;
  $ENV{'LANG'} = 'en_IN.UTF8';
  $ENV{'LANG'} = 'ar_IN';
  $ENV{'LANG'} = 'ja_JP.UTF8';
  $ENV{'LANG'} = 'ja_JP';
  POSIX::setlocale(POSIX::LC_ALL(), '') or die;
  my $bytes = POSIX::strftime ("%b", localtime(time()));
  ### $bytes
  foreach my $i (0 .. length($bytes)-1) {
    printf " %02X", ord(substr($bytes,$i,1));
  }
  print "\n";
  my $str = Encode::decode('euc-jp',$bytes);
  foreach my $i (0 .. length($str)-1) {
    printf " %02X", ord(substr($str,$i,1));
  }
  print "\n";
  exit 0;
}
{
  require Encode;
  my @all_encodings = Encode->encodings(":all");
  foreach my $encoding (@all_encodings) {
    print "$encoding\n";
  }
  exit 0;
}

sub bytestr {
  my ($bytes) = @_;
  return sprintf('[%d bytes] ', length($bytes))
    . join(" ",
           map { sprintf('%02X', ord(substr($bytes,$_,1))) }
           0 .. length($bytes)-1);
}


# foreach my $coding ('jp', 'kr') {
#   last unless length($remainder);
#   my $input = $str;
#   my $bytes = Encode::encode ("euc-$coding", $input, Encode::FB_QUIET());
#   ### coding: "euc-$coding"
#   ### $bytes
#   ### remainder: length($input)
#   if (length($input) < length($remainder)) {
#     my $input2 = substr ($str, 0, length($str)-length($input));
#     ### $input2
#     $bytes = Encode::encode ("iso-2022-$coding", $input2,
#                              Encode::FB_QUIET());
#     ### coding: "iso-2022-$coding"
#     ### $bytes
#     ### remainder: length($input2)
#     ### assert: length($input2) == 0
#     if (length($input2) == 0) {
#       $longest_bytes = $bytes;
#       $esc = '';
#       $remainder = $input;
#       $in_latin1 = 0;
#       $in_ascii = 0;
#     }
#   }
# }

