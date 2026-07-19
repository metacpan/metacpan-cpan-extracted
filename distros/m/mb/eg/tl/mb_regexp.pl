#!/usr/bin/perl
######################################################################
# eg/tl/mb_regexp.pl - multibyte-aware na pagtutugma gamit ang mb::qr
#
# Ano ang ipinapakita:
#   Kino-compile ng mb::qr(PATTERN) ang isang regular expression na ang
#   ".", mga character class at capture ay gumagana sa buong multibyte na
#   KARAKTER ayon sa napiling script encoding.
#
# Pagkakaiba sa CORE:
#   Tumutugma ang CORE "." sa iisang OCTET, kaya ang /(.)/g sa tatlong
#   hiragana ng Shift_JIS ay nagbubunga ng anim na piraso. Ang parehong
#   pattern sa pamamagitan ng mb::qr ay nagbubunga ng tatlo, isa bawat
#   karakter. Ang class range gaya ng [a-hiragana ...] ay naghahambing
#   ng buong karakter, at ang capture ay nagbabalik ng buong karakter.
#
# US-ASCII ang source; gumagamit ang multibyte data ng \xHH byte escape.
# Ito ang runtime interface (walang source filter), kaya tumatakbo ito sa
# bawat perl mula 5.005_03 pataas.
#
#     perl eg/tl/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Tatlong hiragana sa Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# Ang CORE "." ay iisang octet -- anim na piraso para sa anim na byte.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# Ginagawa ng mb::qr("(.)") na buong karakter ang "." -- tatlong piraso.
# I-compile nang isang beses, saka isingit ang compiled pattern sa match.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# Character-class range sa hiragana block a..n (\x82\xA0-\x82\xF1). Ang
# range ay naghahambing ng buong karakter, kaya nasa loob ang u at ang
# ASCII na "A" ay hindi.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# Nagbabalik ang capture ng buong multibyte na karakter (dalawang byte
# dito), hindi kailanman kalahati nito.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Hanapin ang bawat hiragana sa isang halong string, sa yunit ng karakter.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
