#!/usr/bin/perl
######################################################################
# eg/si/mb_length.pl - mb මගින් අක්ෂර ගණන සහ byte ගණන
#
# පෙන්වන දේ:
#   CORE length() මගින් byte ගණන් කරයි; mb::length() මගින් තෝරාගත්
#   script encoding යටතේ සම්පූර්ණ multibyte අක්ෂරයක් 1 ලෙස ගණන් කරයි.
#   mb::substr() සහ mb::index() ද අක්ෂර වශයෙන් ක්‍රියා කරයි.
#
# CORE වලින් වෙනස:
#   double-byte hiragana එකට length නම් 2 (byte); mb::length නම් 1
#   (Shift_JIS hiragana අක්ෂරයක්).
#
# සටහන: source code සහ \xHH data US-ASCII ලෙසම තබයි; මෙම file එක UTF-8 වේ (comment පමණක් සිංහලෙන්).
#
#     perl eg/si/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS hiragana තුනක්, මුළු byte 6ක්:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() byte ගණන් කරයි; mb::length() අක්ෂර ගණන් කරයි.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() අක්ෂර වශයෙන් කපයි, double-byte අක්ෂරය අඩකට නොකැපේ.
# පළමු අක්ෂර 2 හරියටම byte 4ක string එකකි.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() byte නොව අක්ෂර ස්ථානය දෙයි. තෙවන අක්ෂරය byte 4න්
# ඇරඹේ, නමුත් අක්ෂර index 2 හිය.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
