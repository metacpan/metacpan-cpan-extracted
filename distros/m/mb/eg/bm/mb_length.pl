#!/usr/bin/perl
######################################################################
# eg/bm/mb_length.pl - mengira aksara berbanding byte dengan mb
#
# Apa yang ditunjukkan:
#   length() CORE mengira OKTET (byte); mb::length() mengira AKSARA
#   multibyte penuh mengikut pengekodan skrip yang dipilih. mb::substr()
#   dan mb::index() juga bekerja dalam unit aksara, jadi aksara dua-byte
#   tidak pernah dipotong separuh.
#
# Bezanya dengan CORE:
#   length("\x82\xA0") ialah 2 (byte), tetapi mb::length("\x82\xA0") ialah 1
#   (satu hiragana Shift_JIS).
#
# Nota: kod sumber dan data \xHH kekal US-ASCII; fail ini juga
# US-ASCII (komen dalam bahasa Melayu).
#
#     perl eg/bm/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Tiga hiragana dalam Shift_JIS, enam byte semuanya:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# length() CORE mengira byte; mb::length() mengira aksara.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() menghiris dalam unit aksara, jadi aksara dua-byte tidak
# terpotong separuh. Dua aksara pertama ialah rentetan tepat 4 byte.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() melaporkan kedudukan dalam aksara, bukan byte. Aksara ketiga
# bermula pada byte 4, tetapi pada indeks aksara 2.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
