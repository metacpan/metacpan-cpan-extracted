#!/usr/bin/perl
######################################################################
# eg/uz/mb_length.pl - mb bilan belgi va bayt sanashni solishtirish
#
# Nimani ko'rsatadi:
#   CORE length() OKTET (bayt) sanaydi; mb::length() tanlangan skript
#   kodlashiga ko'ra butun ko'p baytli BELGILARNI sanaydi. mb::substr() va
#   mb::index() ham belgi birligida ishlaydi, shuning uchun ikki baytli belgi
#   hech qachon o'rtasidan bo'linmaydi.
#
# CORE dan farqi:
#   length("\x82\xA0") 2 ga teng (bayt), lekin mb::length("\x82\xA0") 1 ga
#   teng (bitta Shift_JIS hiragana).
#
# Eslatma: manba va \xHH ma'lumotlar US-ASCII bo'lib qoladi; bu fayl
# ham US-ASCII (izohlar o'zbekcha).
#
#     perl eg/uz/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS da uchta hiragana, jami olti bayt:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() baytni sanaydi; mb::length() belgini sanaydi.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() belgi birligida kesadi, shuning uchun ikki baytli belgi yarmiga
# bo'linmaydi. Birinchi 2 belgi aniq 4 baytli satr bo'ladi.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() o'rinni baytda emas, belgida qaytaradi. Uchinchi belgi bayt 4
# da boshlanadi, lekin belgi indeksi 2 da.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
