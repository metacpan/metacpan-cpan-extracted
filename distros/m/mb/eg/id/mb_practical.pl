#!/usr/bin/perl
######################################################################
# eg/id/mb_practical.pl - memangkas kolom tetap tanpa merusak karakter
#
# Apa yang ditunjukkan (tugas kecil dunia nyata):
#   Pangkas satu baris Shift_JIS ke LEBAR TAMPILAN tetap untuk keluaran
#   kolom-tetap, menghitung karakter lebar-separuh sebagai 1 kolom dan
#   karakter lebar-penuh sebagai 2 kolom (rasio klasik 1:2), dan tidak
#   pernah membelah karakter dua-byte pada batasnya.
#
# Bedanya dengan CORE:
#   CORE substr(EXPR, 0, N) yang naif memotong pada OKTET ke-N dan bisa
#   menyisakan lead byte menggantung -- separuh karakter yang rusak. Di
#   sini kita menyusuri karakter utuh dengan mb::split(''), mengukur
#   lebar tiap karakter dari panjang byte-nya (1 byte -> 1 kolom, 2 byte
#   -> 2 kolom), dan berhenti sebelum anggaran terlampaui. mb::length()
#   memastikan hasilnya bilangan bulat karakter.
#
# Sumber ini US-ASCII; data multibyte memakai escape byte \xHH. Hanya
# antarmuka runtime, jadi jalan pada setiap perl dari 5.005_03 ke atas.
#
#     perl eg/id/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C lalu tiga hiragana lebar-penuh a i u lalu dua katakana lebar-separuh.
#   ASCII A B C            : 1 kolom masing-masing
#   lebar-penuh a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 kolom masing-masing
#   lebar-separuh ka(\xB6) ki(\xB7)                 : 1 kolom masing-masing
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # pangkas ke 7 kolom tampilan

# Pangkas aman-batas-karakter yang sadar-lebar.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 byte -> 1 kolom, 2 byte -> 2 kolom
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 kolom) + a (2) + i (2) = 7 kolom; u akan meluap dan dibuang,
# jadi karakter dua-byte di akhir tetap utuh.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# Kontras pada data yang seluruhnya dua-byte: memotong pada jumlah OKTET
# tetap bisa mendarat di dalam karakter. Hiragana a i u semuanya dua-byte,
# jadi panjang byte ganjil berarti potongan membelah karakter; mb::substr
# selalu berhenti pada batas karakter (panjang byte genap di sini).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + lead byte menggantung
$char_cut  = mb::substr($aiu, 0, 1);    # tepat a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
