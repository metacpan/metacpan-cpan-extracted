#!/usr/bin/perl
######################################################################
# eg/si/mb_regexp.pl - mb::qr මගින් multibyte-දැනුවත් matching
#
# පෙන්වන දේ:
#   mb::qr(PATTERN) මගින් ".", character class සහ capture තෝරාගත්
#   script encoding යටතේ සම්පූර්ණ අක්ෂර වශයෙන් ක්‍රියා කරන regexp සම්පාදනය කරයි.
#
# CORE වලින් වෙනස:
#   CORE "." එකක් byte එකක් ගළපයි, එ නිසා hiragana තුනකට /(.)/g මගින්
#   කැබලි 6ක්; mb::qr හරහා 3ක් (අක්ෂරයට එකක්). class range සහ capture
#   මගින් සම්පූර්ණ අක්ෂර ලබාදෙයි.
#
# සටහන: source code සහ \xHH data US-ASCII ලෙසම තබයි; මෙම file එක UTF-8 වේ (comment පමණක් සිංහලෙන්).
#
#     perl eg/si/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS hiragana තුනක්: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE "." එකක් byte එකක් -- byte 6කට කැබලි 6ක්.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") මගින් "." සම්පූර්ණ අක්ෂරයක් කරයි -- කැබලි 3ක්. වරක් compile
# කර, compile කළ pattern එක match එකට යොදන්න.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# hiragana block a..n (\x82\xA0-\x82\xF1) මත class range. range මගින් සම්පූර්ණ
# අක්ෂර සසඳයි, එ නිසා u ඇතුළත, ASCII "A" නැත.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# capture මගින් සම්පූර්ණ multibyte අක්ෂරයක් (මෙහි byte දෙකක්) ලබාදෙයි,
# කිසිදා අඩ අක්ෂරයක් නොවේ.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# මිශ්‍ර string එකක සෑම hiragana එකක්ම, අක්ෂර වශයෙන් සොයන්න.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
