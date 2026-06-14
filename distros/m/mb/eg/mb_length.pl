#!/usr/bin/perl
######################################################################
# eg/mb_length.pl - MBCS-aware string operations with mb
#
# The whole point of mb is that CORE string operators see bytes, while
# mb's operators see whole multibyte characters under the selected
# script encoding. This example shows the difference.
#
# The source of this file is deliberately US-ASCII: the multibyte data
# is written with \xHH byte escapes, so the example stays portable
# while mb still treats the bytes as whole characters.
#
# Run it after the module is installed (or from the distribution root):
#
#     perl eg/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../lib";
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
