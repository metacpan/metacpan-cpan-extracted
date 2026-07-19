#!/usr/bin/perl
######################################################################
# eg/bm/mb_tr.pl - transliterasi unit-aksara dengan mb::tr
#
# Apa yang ditunjukkan:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) mentransliterasi AKSARA
#   multibyte penuh. Tanpa /r ia menyunting argumen pertamanya di tempat
#   dan memulangkan kiraan; dengan /r ia memulangkan hasil dan membiarkan
#   argumen tidak tersentuh.
#
# Bezanya dengan CORE:
#   CORE tr/// bekerja oktet demi oktet, jadi ia boleh merosakkan DAMEMOJI
#   -- aksara dua-byte yang byte KEDUAnya ialah metakarakter ASCII, cth.
#   So(\x83\x5C), yang byte akhirnya \x5C ialah garis serong belakang.
#   CORE tr pada \x5C akan mengena byte akhir itu; mb::tr melihat So
#   sebagai satu aksara dan membiarkannya.
#
# Nota: dalam mb::tr julat sengkang (a-z) dikembangkan hanya untuk hujung
# US-ASCII; aksara multibyte dalam SEARCH mesti disenaraikan satu demi satu
# (tepat seperti transpiler mengembangkan tr/// MBCS).
#
# Nota: kod sumber dan data \xHH kekal US-ASCII; fail ini juga
# US-ASCII (komen dalam bahasa Melayu).
#
#     perl eg/bm/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Digit lebar-penuh dalam Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH menyenaraikan sepuluh digit lebar-penuh satu demi satu; REPLACE
# ialah julat US-ASCII "0-9" (julat sengkang ASCII yang mb::tr kembangkan).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# Lebar-penuh "1" "3" "6" -> lebar-separuh "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# Keselamatan DAMEMOJI. Rentetannya A So(\x83\x5C) B. CORE tr yang menyasar
# byte garis serong belakang \x5C merosakkan aksara; mb::tr, yang memeta
# hanya huruf ASCII, membiarkan So utuh.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr mengena byte akhir So
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# Pengubah /r: tidak memusnah, memulangkan salinan yang ditransliterasi.
$keep = "\x82\x50\x82\x51";                 # lebar-penuh 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
