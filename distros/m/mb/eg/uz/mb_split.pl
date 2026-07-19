#!/usr/bin/perl
######################################################################
# eg/uz/mb_split.pl - mb::split bilan belgi chegaralarida bo'lish
#
# Nimani ko'rsatadi:
#   mb::split('', EXPR) satrni butun ko'p baytli BELGILARGA ajratadi, va
#   mb::split(PATTERN, EXPR) MBCS ajratgichi bo'yicha bo'ladi hamda ko'p
#   baytli belgi ichidagi baytga hech qachon mos kelmaydi.
#
# CORE dan farqi:
#   CORE split(//, "\x82\xA0") ikkita OKTET qaytaradi ("\x82", "\xA0");
#   ikki baytli hiragana bo'lib ketadi. mb::split('', ...) uni bitta belgi
#   sifatida qaytaradi. mb::split transpil qilingan "split //" ning ish
#   vaqti muqobili bo'lib, Perl 5.005_03 gacha mos keladi.
#
# Eslatma: manba va \xHH ma'lumotlar US-ASCII bo'lib qoladi; bu fayl
# ham US-ASCII (izohlar o'zbekcha).
#
#     perl eg/uz/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS da uchta hiragana: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) baytlarni ko'radi: bu yerda oltita.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) belgilarni ko'radi: uchta.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS ajratgichi bo'yicha bo'lish. Ajratgich hiragana a
# (\x82\xA0); mb::split uni butun belgi sifatida topadi, \x82 yoki \xA0
# baytlari qayerda uchramasin ularga qaramaydi.
#     A a B a C  ->  maydonlar: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# mb::split ning ro'yxat kontekstida belgilar soni (chars() yordamchisi kabi).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
