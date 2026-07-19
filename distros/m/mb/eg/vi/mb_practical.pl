#!/usr/bin/perl
######################################################################
# eg/vi/mb_practical.pl - cat theo cot co dinh ma khong lam vo ky tu
#
# Vi du nay cho thay (mot tac vu thuc te nho):
#   Cat mot dong Shift_JIS ve mot BE RONG HIEN THI co dinh, ky tu nua
#   chieu la 1 cot va ky tu day du la 2 cot (ti le 1:2 quen thuoc), va
#   khong bao gio cat mot ky tu hai byte ngang qua ranh gioi.
#
# Khac CORE the nao:
#   substr CORE ngay tho cat tai byte thu N va co the de lai nua ky tu.
#   O day ta di qua tron ky tu bang mb::split(''), do be rong theo do dai
#   byte, va dung truoc khi vuot ngan sach. mb::length() xac nhan ket qua.
#
# Ghi chu: ma nguon va du lieu \xHH giu US-ASCII; tep nay la UTF-8 (chi comment tieng Viet).
#
#     perl eg/vi/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C roi ba hiragana day du a i u roi hai katakana nua chieu.
#   ASCII A B C            : 1 column each
#   full-width a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 columns each
#   half-width ka(\xB6) ki(\xB7)                   : 1 column each
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # cat ve 7 cot hien thi

# Cat an toan theo ranh gioi ky tu, co tinh be rong.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 byte -> 1 cot, 2 byte -> 2 cot
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 cot) + a (2) + i (2) = 7 cot; u se tran nen bi bo di, do do
# ky tu hai byte cuoi van con nguyen ven.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# So sanh tren du lieu chi hai byte: cat theo so byte co dinh co the roi
# vao giua mot ky tu. Hiragana a i u deu hai byte, nen do dai byte le
# nghia la cat da xe mot ky tu; mb::substr luon dung o ranh gioi ky tu
# (do dai byte chan o day).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + mot byte dan dau lung lang
$char_cut  = mb::substr($aiu, 0, 1);    # dung a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
