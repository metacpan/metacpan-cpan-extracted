#!/usr/bin/perl
######################################################################
# eg/en/mb_practical.pl - fixed-column trimming without breaking chars
#
# What this shows (a small real-world task):
#   Trim a Shift_JIS line to a fixed DISPLAY WIDTH for fixed-column
#   output, counting a half-width character as 1 column and a full-width
#   character as 2 columns (the classic 1:2 ratio), and never splitting a
#   double-byte character across the boundary.
#
# How it differs from CORE:
#   A naive CORE substr(EXPR, 0, N) cuts at the N-th OCTET and can leave a
#   dangling lead byte -- a broken half of a character. Here we walk whole
#   characters with mb::split(''), measure each character's width by its
#   byte length (1 byte -> 1 column, 2 bytes -> 2 columns), and stop
#   before the budget is exceeded. mb::length() confirms the result is a
#   whole number of characters.
#
# The source is US-ASCII; multibyte data uses \xHH byte escapes. Runtime
# interface only, so it runs on every perl from 5.005_03 up.
#
#     perl eg/en/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C then three full-width hiragana a i u then two half-width katakana.
#   ASCII A B C            : 1 column each
#   full-width a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 columns each
#   half-width ka(\xB6) ki(\xB7)                   : 1 column each
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # trim to 7 display columns

# Character-boundary-safe, width-aware trim.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 byte -> 1 column, 2 bytes -> 2 columns
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 columns) + a (2) + i (2) = 7 columns; u would overflow and is
# dropped, so the trailing double-byte character stays whole.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# Contrast on double-byte-only data: cutting at a fixed OCTET count can
# land inside a character. The hiragana a i u is all double-byte, so an
# odd byte length means the cut split a character; mb::substr always
# stops on a character boundary (an even byte length here).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + a dangling lead byte
$char_cut  = mb::substr($aiu, 0, 1);    # exactly a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
