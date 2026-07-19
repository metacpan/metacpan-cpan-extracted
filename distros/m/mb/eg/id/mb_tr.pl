#!/usr/bin/perl
######################################################################
# eg/id/mb_tr.pl - transliterasi satuan-karakter dengan mb::tr
#
# Apa yang ditunjukkan:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) mentransliterasi
#   KARAKTER multibyte utuh. Tanpa /r ia menyunting argumen pertamanya
#   di tempat dan mengembalikan jumlahnya; dengan /r ia mengembalikan
#   hasilnya dan membiarkan argumen tak tersentuh.
#
# Bedanya dengan CORE:
#   CORE tr/// bekerja oktet demi oktet, jadi bisa merusak DAMEMOJI --
#   karakter dua-byte yang byte KEDUA-nya adalah metakarakter ASCII,
#   mis. So(\x83\x5C), yang byte akhirnya \x5C adalah backslash. CORE tr
#   pada \x5C akan mengenai byte akhir itu; mb::tr melihat So sebagai
#   satu karakter dan membiarkannya.
#
# Catatan: dalam mb::tr rentang tanda hubung (a-z) diperluas hanya untuk
# ujung US-ASCII; karakter multibyte di SEARCH harus didaftar satu per
# satu (persis seperti transpiler memperluas tr/// MBCS).
#
# Sumber ini US-ASCII; data multibyte memakai escape byte \xHH.
#
#     perl eg/id/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Angka lebar-penuh Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH mendaftar kesepuluh angka lebar-penuh sebagai karakter utuh;
# REPLACE adalah rentang US-ASCII "0-9" (rentang hubung ASCII yang
# diperluas mb::tr).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# Lebar-penuh "1" "3" "6" -> lebar-separuh "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# Keamanan DAMEMOJI. String-nya A So(\x83\x5C) B. CORE tr yang menyasar
# byte backslash \x5C merusak karakter itu; mb::tr, yang hanya memetakan
# huruf ASCII, membiarkan So utuh.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr mengenai byte akhir So
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# Modifier /r: non-destruktif, mengembalikan salinan hasil transliterasi.
$keep = "\x82\x50\x82\x51";                 # lebar-penuh 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
