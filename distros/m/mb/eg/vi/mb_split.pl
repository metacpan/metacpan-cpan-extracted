#!/usr/bin/perl
######################################################################
# eg/vi/mb_split.pl - tach theo ranh gioi ky tu bang mb::split
#
# Vi du nay cho thay:
#   mb::split('', EXPR) tach chuoi thanh tron ky tu da byte, va
#   mb::split(PATTERN, EXPR) tach theo dau phan cach MBCS ma khong
#   bao gio khop mot byte nam ben trong mot ky tu.
#
# Khac CORE the nao:
#   CORE split(//) xe hiragana hai byte thanh hai byte; mb::split giu
#   no la mot ky tu. Tuong thich nguoc ve Perl 5.005_03.
#
# Ghi chu: ma nguon va du lieu \xHH giu US-ASCII; tep nay la UTF-8 (chi comment tieng Viet).
#
#     perl eg/vi/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Ba hiragana Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) thay byte: sau cai o day.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) thay ky tu: ba cai.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# Tach theo dau phan cach MBCS. Dau la hiragana a (\x82\xA0); mb::split
# khop no nhu mot ky tu tron ven, khong phai byte \x82 hay \xA0 o bat cu dau.
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# Dem ky tu qua ngu canh danh sach cua mb::split (nhu ham chars()).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
