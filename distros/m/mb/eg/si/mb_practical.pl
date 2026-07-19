#!/usr/bin/perl
######################################################################
# eg/si/mb_practical.pl - අක්ෂර නොකඩා ස්ථාවර-column කැපීම
#
# පෙන්වන දේ (කුඩා practical කාර්යයක්):
#   Shift_JIS line එකක් ස්ථාවර display width එකකට කැපීම — half-width අක්ෂරය
#   column 1ක්, full-width අක්ෂරය column 2ක් (සුපුරුදු 1:2 අනුපාතය), double-byte
#   අක්ෂරයක් මායිමෙන් නොකඩා.
#
# CORE වලින් වෙනස:
#   සරල CORE substr N-වන byte එකෙන් කපා අඩ අක්ෂරයක් තැබිය හැක. මෙහිදී
#   mb::split('') මගින් සම්පූර්ණ අක්ෂර ඔස්සේ ගොස්, byte දිග අනුව width මැන,
#   budget ඉක්මවීමට පෙර නවතී. mb::length() මගින් සම්පූර්ණ අක්ෂර තහවුරු කරයි.
#
# සටහන: source code සහ \xHH data US-ASCII ලෙසම තබයි; මෙම file එක UTF-8 වේ (comment පමණක් සිංහලෙන්).
#
#     perl eg/si/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C, ඉන්පසු full-width hiragana තුනක් a i u, ඉන්පසු half-width katakana දෙකක්.
#   ASCII A B C            : 1 column each
#   full-width a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 columns each
#   half-width ka(\xB6) ki(\xB7)                   : 1 column each
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # display column 7කට කැපීම

# අක්ෂර-මායිම ආරක්ෂිත, width-දැනුවත් කැපීම.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # byte 1 -> column 1, byte 2 -> column 2
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (column 3) + a (2) + i (2) = column 7; u පිටාර යන නිසා ඉවතලයි,
# එ නිසා අග double-byte අක්ෂරය සම්පූර්ණව පවතී.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# double-byte-only data මත සැසඳීම: ස්ථාවර byte ගණනකින් කැපීම අක්ෂරයක්
# ඇතුළට වැටිය හැක. hiragana a i u සියල්ල double-byte, එ නිසා ඔත්තේ byte දිග
# යනු කැපීම අක්ෂරයක් ඉරූ බවයි; mb::substr සැම විටම අක්ෂර මායිමේ නවතී
# (මෙහි ඉරට්ටේ byte දිග).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + එල්ලෙන lead byte එකක්
$char_cut  = mb::substr($aiu, 0, 1);    # හරියටම a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
