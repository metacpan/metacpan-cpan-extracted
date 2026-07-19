#!/usr/bin/perl
######################################################################
# eg/ur/mb_practical.pl - character tode baghair fixed-column trimming
#
# Yeh misal kya dikhati hai (ek chhota haqeeqi kaam):
#   Fixed-column output ke liye kisi Shift_JIS line ko ek muqarrar DISPLAY
#   WIDTH tak trim karein, half-width character ko 1 column aur full-width
#   character ko 2 column ginte hue (classic 1:2 ratio), aur kisi do-byte
#   character ko hadd par kabhi na todein.
#
# CORE se kya farq hai:
#   Sada CORE substr(EXPR, 0, N) N-wein OCTET par kaatta hai aur ek latakta
#   hua lead byte chhod sakta hai -- character ka toota hua aadha. Yahan
#   hum mb::split('') se poore characters par chalte hain, har character
#   ki width us ki byte length se naapte hain (1 byte -> 1 column, 2 byte
#   -> 2 column), aur budget se aage barhne se pehle ruk jaate hain.
#   mb::length() tasdeeq karta hai ke nateeja characters ki poori tadaad hai.
#
# Source US-ASCII hai; multibyte data \xHH byte escape istemal karta hai.
# Sirf runtime interface, is liye yeh 5.005_03 se aage har perl par chalta hai.
#
#     perl eg/ur/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C phir teen full-width hiragana a i u phir do half-width katakana.
#   ASCII A B C            : har ek 1 column
#   full-width a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : har ek 2 column
#   half-width ka(\xB6) ki(\xB7)                   : har ek 1 column
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # 7 display column tak trim

# Character-hadd-mehfooz, width-aware trim.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 byte -> 1 column, 2 byte -> 2 column
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 column) + a (2) + i (2) = 7 column; u overflow ho kar hataya
# jaata hai, is liye aakhri do-byte character poora rehta hai.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# Sirf-do-byte data par muqabla: muqarrar OCTET tadaad par kaatna kisi
# character ke andar utar sakta hai. Hiragana a i u sabhi do-byte hain,
# is liye taaq byte length ka matlab hai ke cut ne character toda; mb::substr
# hamesha character ki hadd par rukta hai (yahan juft byte length).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + latakta hua lead byte
$char_cut  = mb::substr($aiu, 0, 1);    # theek a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
