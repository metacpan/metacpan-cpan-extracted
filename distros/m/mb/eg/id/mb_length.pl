#!/usr/bin/perl
######################################################################
# eg/id/mb_length.pl - menghitung karakter vs byte dengan mb
#
# Apa yang ditunjukkan:
#   length() CORE menghitung OKTET (byte); mb::length() menghitung
#   KARAKTER multibyte utuh menurut script encoding yang dipilih.
#   mb::substr() dan mb::index() juga bekerja dalam satuan karakter,
#   jadi karakter dua-byte tidak pernah terpotong setengah.
#
# Bedanya dengan CORE:
#   length("\x82\xA0") adalah 2 (byte), tetapi mb::length("\x82\xA0")
#   adalah 1 (satu hiragana Shift_JIS).
#
# Catatan: kode sumber dan data \xHH tetap US-ASCII; file ini juga US-ASCII (komentar bahasa Indonesia).
#
#     perl eg/id/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Tiga huruf hiragana Shift_JIS, total enam byte:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# length() CORE menghitung byte; mb::length() menghitung karakter.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() memotong dalam satuan karakter, jadi karakter dua-byte
# tidak terbelah. Dua karakter pertama tepat berupa string 4 byte.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() melaporkan posisi dalam karakter, bukan byte. Karakter
# ketiga mulai pada byte 4, tetapi pada indeks karakter 2.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
