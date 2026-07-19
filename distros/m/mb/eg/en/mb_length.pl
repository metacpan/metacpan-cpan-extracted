#!/usr/bin/perl
######################################################################
# eg/en/mb_length.pl - counting characters vs bytes with mb
#
# What this shows:
#   CORE length() counts OCTETS; mb::length() counts whole multibyte
#   CHARACTERS under the selected script encoding. mb::substr() and
#   mb::index() work in character units too, so a double-byte character
#   is never cut in half.
#
# How it differs from CORE:
#   length("\x82\xA0") is 2 (bytes), but mb::length("\x82\xA0") is 1
#   (one Shift_JIS hiragana).
#
# The source is deliberately US-ASCII: the multibyte data is written
# with \xHH byte escapes so the example stays portable while mb still
# treats those bytes as whole characters. Run from the distribution
# root (or after install):
#
#     perl eg/en/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Three hiragana letters in Shift_JIS, six bytes in total:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() counts bytes; mb::length() counts characters.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() slices in character units, so a double-byte character is
# never cut in half. The first two characters are a clean 4-byte string.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() reports the position in characters, not bytes. The third
# character starts at byte 4, but at character index 2.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
