#!/usr/bin/perl
######################################################################
# eg/tl/mb_length.pl - pagbilang ng karakter kumpara sa byte gamit ang mb
#
# Ano ang ipinapakita:
#   Binibilang ng CORE length() ang mga OCTET (byte); binibilang ng
#   mb::length() ang buong multibyte na KARAKTER ayon sa napiling script
#   encoding. Gumagana rin sa yunit ng karakter ang mb::substr() at
#   mb::index(), kaya hindi kailanman napuputol sa gitna ang isang
#   dalawang-byte na karakter.
#
# Pagkakaiba sa CORE:
#   Ang length("\x82\xA0") ay 2 (byte), ngunit ang mb::length("\x82\xA0")
#   ay 1 (isang hiragana ng Shift_JIS).
#
# Tandaan: nananatiling US-ASCII ang source at ang \xHH data; US-ASCII din ang file na ito (komento sa Tagalog).
#
#     perl eg/tl/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Tatlong hiragana sa Shift_JIS, anim na byte lahat:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# Binibilang ng CORE length() ang byte; ng mb::length() ang karakter.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# Naghihiwa ang mb::substr() sa yunit ng karakter, kaya hindi napuputol
# nang kalahati ang dalawang-byte na karakter. Ang unang 2 karakter ay
# tumpak na string na 4 byte.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# Iniuulat ng mb::index() ang posisyon sa karakter, hindi sa byte. Ang
# ikatlong karakter ay nagsisimula sa byte 4, ngunit sa index 2 ng karakter.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
