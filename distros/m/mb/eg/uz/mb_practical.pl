#!/usr/bin/perl
######################################################################
# eg/uz/mb_practical.pl - ikki baytlini buzmasdan qat'iy ustunga qirqish
#
# Nimani ko'rsatadi (kichik amaliy vazifa):
#   Shift_JIS satrini qat'iy ustunli chiqish uchun qat'iy KO'RSATISH
#   KENGLIGIGA qirqish; yarim kenglik belgini 1 ustun, to'liq kenglik
#   belgini 2 ustun deb sanash (klassik 1:2 nisbat) va ikki baytli belgini
#   chegaradan hech qachon bo'lmaslik.
#
# CORE dan farqi:
#   Sodda CORE substr(EXPR, 0, N) N-chi OKTETda kesadi va osilib qolgan bosh
#   bayt -- belgining buzilgan yarmi -- qoldirishi mumkin. Bu yerda butun
#   belgilarni mb::split('') bilan aylanamiz, har belgining kengligini bayt
#   uzunligidan o'lchaymiz (1 bayt -> 1 ustun, 2 bayt -> 2 ustun) va byudjet
#   oshib ketishidan oldin to'xtaymiz. mb::length() natija butun sondagi
#   belgi ekanini tasdiqlaydi.
#
# Eslatma: manba va \xHH ma'lumotlar US-ASCII bo'lib qoladi; bu fayl
# ham US-ASCII (izohlar o'zbekcha).
#
#     perl eg/uz/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C, so'ng uchta to'liq kenglik hiragana a i u, so'ng ikkita yarim kenglik katakana.
#   ASCII A B C            : har biri 1 ustun
#   to'liq kenglik a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : har biri 2 ustun
#   yarim kenglik ka(\xB6) ki(\xB7)                   : har biri 1 ustun
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # 7 ko'rsatish ustuniga qirq

# Belgi-chegarasiga xavfsiz, kenglikka sezgir qirqish.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 bayt -> 1 ustun, 2 bayt -> 2 ustun
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 ustun) + a (2) + i (2) = 7 ustun; u toshib ketardi va tashlanadi,
# shuning uchun oxirgi ikki baytli belgi butun qoladi.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# Faqat ikki baytli ma'lumotda solishtirish: qat'iy OKTET sonida kesish belgi
# ichiga tushishi mumkin. Hiragana a i u butunlay ikki baytli, shuning uchun
# toq bayt uzunligi kesish belgini bo'lganini bildiradi; mb::substr har doim
# belgi chegarasida to'xtaydi (bu yerda juft bayt uzunligi).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + osilib qolgan bosh bayt
$char_cut  = mb::substr($aiu, 0, 1);    # aniq a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
