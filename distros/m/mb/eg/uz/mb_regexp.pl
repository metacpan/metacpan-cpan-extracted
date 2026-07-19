#!/usr/bin/perl
######################################################################
# eg/uz/mb_regexp.pl - mb::qr bilan ko'p baytga sezgir moslash
#
# Nimani ko'rsatadi:
#   mb::qr(PATTERN) shunday muntazam ifoda kompilyatsiya qiladiki, uning
#   "." belgisi, belgi sinflari va ushlashlari tanlangan skript kodlashiga
#   ko'ra butun ko'p baytli BELGILAR ustida ishlaydi.
#
# CORE dan farqi:
#   CORE "." bitta OKTETga mos keladi, shuning uchun uchta Shift_JIS hiragana
#   ustida /(.)/g oltita bo'lak beradi. Xuddi shu naqsh mb::qr orqali uchta
#   beradi, har belgiga bittadan. [a-hiragana ... ] kabi sinf oralig'i butun
#   belgilarni solishtiradi, ushlash esa butun belgini qaytaradi.
#
# Eslatma: manba va \xHH ma'lumotlar US-ASCII bo'lib qoladi; bu fayl
# ham US-ASCII (izohlar o'zbekcha).
#
#     perl eg/uz/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS da uchta hiragana: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE "." bitta oktet -- olti bayt uchun oltita bo'lak.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") "." ni bitta butun belgi qiladi -- uchta bo'lak. Bir marta
# kompilyatsiya qil, so'ng kompilyatsiya qilingan naqshni moslashga qo'y.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# Hiragana bloki a..n (\x82\xA0-\x82\xF1) ustida belgi-sinfi oralig'i.
# Oraliq butun belgilarni solishtiradi, shuning uchun u ichida, ASCII "A" emas.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# Ushlash butun ko'p baytli belgini qaytaradi (bu yerda ikki bayt), hech
# qachon uning yarmini emas.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Aralash satrdagi har bir hiraganani belgi birligida top.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
