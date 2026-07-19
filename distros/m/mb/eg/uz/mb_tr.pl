#!/usr/bin/perl
######################################################################
# eg/uz/mb_tr.pl - mb::tr bilan belgi birligida transliteratsiya
#
# Nimani ko'rsatadi:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) butun ko'p baytli
#   BELGILARNI transliteratsiya qiladi. /r siz birinchi argumentini joyida
#   o'zgartiradi va sonini qaytaradi; /r bilan natijani qaytaradi va
#   argumentga tegmaydi.
#
# CORE dan farqi:
#   CORE tr/// oktet-oktet ishlaydi, shuning uchun DAMEMOJI ni buzishi mumkin
#   -- IKKINCHI bayti ASCII meta-belgisi bo'lgan ikki baytli belgi, masalan
#   So(\x83\x5C), uning oxirgi bayti \x5C teskari chiziq. \x5C ustidagi
#   CORE tr o'sha oxirgi baytga tegadi; mb::tr So ni bitta belgi sifatida
#   ko'radi va unga tegmaydi.
#
# Eslatma: mb::tr da tire oralig'i (a-z) faqat US-ASCII chekka nuqtalari uchun
# yoyiladi; SEARCH dagi ko'p baytli belgilar bittalab sanab chiqilishi kerak
# (transpiler MBCS tr/// ni yoygani bilan aynan bir xil).
#
# Eslatma: manba va \xHH ma'lumotlar US-ASCII bo'lib qoladi; bu fayl
# ham US-ASCII (izohlar o'zbekcha).
#
#     perl eg/uz/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS da to'liq kenglikdagi raqamlar: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH o'nta to'liq kenglik raqamini bittalab sanaydi; REPLACE US-ASCII
# oralig'i "0-9" (mb::tr yoyadigan ASCII tire oralig'i).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# To'liq kenglik "1" "3" "6" -> yarim kenglik "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI xavfsizligi. Satr A So(\x83\x5C) B. Teskari chiziq bayti \x5C ni
# nishonga olgan CORE tr belgini buzadi; faqat ASCII harflarni moslaydigan
# mb::tr So ni buzilmagan qoldiradi.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr So ning oxirgi baytiga tegadi
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r modifikatori: buzmaydi, transliteratsiya qilingan nusxani qaytaradi.
$keep = "\x82\x50\x82\x51";                 # to'liq kenglik 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
