#!/usr/bin/perl
######################################################################
# eg/bm/mb_practical.pl - pemangkasan lajur tetap tanpa memecahkan aksara
#
# Apa yang ditunjukkan (tugas dunia sebenar yang kecil):
#   Pangkas satu baris Shift_JIS kepada LEBAR PAPARAN tetap untuk output
#   lajur tetap, mengira aksara lebar-separuh sebagai 1 lajur dan aksara
#   lebar-penuh sebagai 2 lajur (nisbah klasik 1:2), dan tidak pernah
#   membelah aksara dua-byte merentas sempadan.
#
# Bezanya dengan CORE:
#   CORE substr(EXPR, 0, N) yang naif memotong pada OKTET ke-N dan boleh
#   meninggalkan byte pendahulu tergantung -- separuh aksara yang rosak. Di
#   sini kita menyusuri aksara penuh dengan mb::split(''), mengukur lebar
#   setiap aksara dari panjang byte (1 byte -> 1 lajur, 2 byte -> 2 lajur)
#   dan berhenti sebelum belanjawan dilampaui. mb::length() mengesahkan
#   hasilnya ialah bilangan aksara yang bulat.
#
# Nota: kod sumber dan data \xHH kekal US-ASCII; fail ini juga
# US-ASCII (komen dalam bahasa Melayu).
#
#     perl eg/bm/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C kemudian tiga hiragana lebar-penuh a i u kemudian dua katakana lebar-separuh.
#   ASCII A B C            : 1 lajur setiap satu
#   lebar-penuh a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 lajur setiap satu
#   lebar-separuh ka(\xB6) ki(\xB7)                   : 1 lajur setiap satu
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # pangkas kepada 7 lajur paparan

# Pemangkasan selamat-sempadan-aksara, sedar-lebar.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 byte -> 1 lajur, 2 byte -> 2 lajur
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 lajur) + a (2) + i (2) = 7 lajur; u akan melimpah dan digugurkan,
# jadi aksara dua-byte terakhir kekal utuh.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# Bandingan pada data dua-byte sahaja: memotong pada kiraan OKTET tetap
# boleh mendarat di dalam aksara. Hiragana a i u semuanya dua-byte, jadi
# panjang byte ganjil bermakna potongan membelah aksara; mb::substr sentiasa
# berhenti pada sempadan aksara (panjang byte genap di sini).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + byte pendahulu tergantung
$char_cut  = mb::substr($aiu, 0, 1);    # tepat a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
