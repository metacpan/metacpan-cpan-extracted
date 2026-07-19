#!/usr/bin/perl
######################################################################
# eg/mn/mb_tr.pl - mb::tr ашиглан тэмдэгтийн нэгжийн галиглал
#
# Энэ жишээ юуг харуулж байна:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) нь бүтэн multibyte
#   ТЭМДЭГТүүдийг галигладаг. /r-гүй бол эхний аргументаа байрандаа
#   засварлаж, тоог буцаана; /r-тэй бол үр дүнг буцааж, аргументыг
#   хөндөхгүй.
#
# CORE-оос юугаараа ялгаатай вэ:
#   CORE tr/// нь octet тус бүрээр ажилладаг тул DAMEMOJI-г эвдэж болно --
#   хоёр дахь байт нь ASCII метатэмдэгт болох хоёр байтын тэмдэгт, ж.нь.
#   So(\x83\x5C), түүний сүүлчийн байт \x5C нь backslash. \x5C дээрх CORE
#   tr тэрхүү сүүлчийн байтад хүрнэ; mb::tr нь So-г нэг тэмдэгт гэж хараад
#   хөндөлгүй орхино.
#
# Тэмдэглэл: mb::tr дотор зураасан муж (a-z) нь зөвхөн US-ASCII төгсгөлд
# өргөтгөгддөг; SEARCH дэх multibyte тэмдэгтүүдийг нэг нэгээр нь жагсаах
# ёстой (transpiler нь MBCS tr///-г яг ингэж өргөтгөдөгтэй адил).
#
# Эх нь US-ASCII; multibyte өгөгдөл \xHH байт escape ашиглана.
#
#     perl eg/mn/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS дахь бүтэн өргөний цифр: 0(\x82\x4F) .. 9(\x82\x58). SEARCH нь
# бүх арван бүтэн өргөний цифрийг бүтэн тэмдэгт болгон жагсаана; REPLACE
# нь US-ASCII "0-9" муж (mb::tr өргөтгөдөг ASCII зураасан муж).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# Бүтэн өргөн "1" "3" "6" -> хагас өргөн "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI аюулгүй байдал. Мөр нь A So(\x83\x5C) B. Backslash байт \x5C-г
# онилсон CORE tr тэмдэгтийг эвдэнэ; зөвхөн ASCII үсгийг map хийдэг mb::tr
# нь So-г бүрэн бүтэн үлдээнэ.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr нь So-ийн сүүлчийн байтад хүрнэ
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r хувиргагч: эвдэхгүй, галигласан хуулбарыг буцаана.
$keep = "\x82\x50\x82\x51";                 # бүтэн өргөн 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
