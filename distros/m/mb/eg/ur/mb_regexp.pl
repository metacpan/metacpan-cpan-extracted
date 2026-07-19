#!/usr/bin/perl
######################################################################
# eg/ur/mb_regexp.pl - mb::qr ke sath multibyte-aware matching
#
# Yeh misal kya dikhati hai:
#   mb::qr(PATTERN) ek regular expression compile karta hai jis ka ".",
#   character class aur capture muntakhab kiye gaye script encoding ke
#   mutabiq poore multibyte CHARACTER mein kaam karte hain.
#
# CORE se kya farq hai:
#   CORE ka "." ek OCTET se match karta hai, is liye teen Shift_JIS
#   hiragana par /(.)/g chhe tukde deta hai. Wahi pattern mb::qr ke
#   zariye teen deta hai, har character ke liye ek. [a-hiragana ...] jaisi
#   class range poore character compare karti hai, aur capture poora
#   character wapas deta hai.
#
# Source US-ASCII hai; multibyte data \xHH byte escape istemal karta hai.
# Yeh runtime interface hai (koi source filter nahin), is liye yeh 5.005_03
# se aage har perl par chalta hai.
#
#     perl eg/ur/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS mein teen hiragana: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE "." ek octet hai -- chhe byte ke liye chhe tukde.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") "." ko ek poora character banata hai -- teen tukde. Ek
# baar compile karein, phir compile kiya pattern match mein daalein.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# Hiragana block a..n (\x82\xA0-\x82\xF1) par character-class range. Range
# poore character compare karti hai, is liye u andar hai aur ASCII "A" nahin.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# Capture ek poora multibyte character (yahan do byte) wapas deta hai,
# kabhi us ka aadha nahin.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Mile-jule string mein har hiragana ko character ki unit mein dhoondein.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
