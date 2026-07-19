#!/usr/bin/perl
######################################################################
# eg/th/mb_split.pl - แยกสตริงที่ขอบตัวอักษรด้วย mb::split
#
# ตัวอย่างนี้แสดงอะไร:
#   mb::split('', EXPR) แตกสตริงเป็นตัวอักษร multibyte ทั้งตัว และ
#   mb::split(PATTERN, EXPR) แยกที่ตัวคั่น MBCS โดยไม่เคยจับคู่ไบต์ที่อยู่
#   ภายในตัวอักษร multibyte
#
# ต่างจาก CORE อย่างไร:
#   CORE split(//, "\x82\xA0") คืนค่าสอง OCTET ("\x82", "\xA0"); ฮิรางานะ
#   สองไบต์ถูกฉีกออก mb::split('', ...) คืนค่าเป็นตัวอักษรเดียว mb::split
#   คือคู่ที่จัดการตอน runtime ของ "split //" ที่ถูก transpile และเข้ากันได้
#   ย้อนหลังถึง Perl 5.005_03
#
# ซอร์สเป็น US-ASCII; ข้อมูล multibyte ใช้ไบต์เอสเคป \xHH
#
#     perl eg/th/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# ฮิรางานะ Shift_JIS สามตัว: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) เห็นไบต์: หกตัวที่นี่
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) เห็นตัวอักษร: สามตัวที่นี่
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# แยกที่ตัวคั่น MBCS ตัวคั่นคือฮิรางานะ a (\x82\xA0); mb::split จับคู่มัน
# เป็นตัวอักษรทั้งตัว ไม่ใช่ไบต์ \x82 หรือ \xA0 ไม่ว่าไบต์เหล่านั้นจะปรากฏ
# ที่ใดก็ตาม
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# นับจำนวนตัวอักษรผ่าน list context ของ mb::split (คล้ายตัวช่วย chars())
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
