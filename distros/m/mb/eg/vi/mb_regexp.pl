#!/usr/bin/perl
######################################################################
# eg/vi/mb_regexp.pl - khop mau nhan biet da byte bang mb::qr
#
# Vi du nay cho thay:
#   mb::qr(PATTERN) bien dich mot regexp ma ".", lop ky tu va nhom
#   bat deu lam viec theo tron ky tu da byte theo script encoding.
#
# Khac CORE the nao:
#   "." cua CORE khop mot byte, nen /(.)/g tren ba hiragana cho 6
#   manh; qua mb::qr cho 3 (moi ky tu mot). Dai lop va nhom bat tra
#   ve tron ky tu.
#
# Ghi chu: ma nguon va du lieu \xHH giu US-ASCII; tep nay la UTF-8 (chi comment tieng Viet).
#
#     perl eg/vi/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Ba hiragana Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# "." cua CORE la mot byte -- sau manh cho sau byte.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") lam "." thanh mot ky tu tron -- ba manh. Bien dich mot
# lan, roi chen mau da bien dich vao phep khop.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# Dai lop ky tu tren khoi hiragana a..n (\x82\xA0-\x82\xF1). Dai so sanh
# tron ky tu nen u nam trong con ASCII "A" thi khong.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# Nhom bat tra ve mot ky tu da byte tron ven (o day hai byte), khong
# bao gio la nua ky tu.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Tim moi hiragana trong chuoi hon hop, theo don vi ky tu.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
