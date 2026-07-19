#!/usr/bin/perl
######################################################################
# eg/th/mb_regexp.pl - การจับคู่ที่รู้จัก multibyte ด้วย mb::qr
#
# ตัวอย่างนี้แสดงอะไร:
#   mb::qr(PATTERN) คอมไพล์ regular expression ที่ ".", character class
#   และ capture ทำงานเป็นตัวอักษร multibyte ทั้งตัวตาม script encoding
#   ที่เลือก
#
# ต่างจาก CORE อย่างไร:
#   "." ของ CORE จับคู่ OCTET เดียว ดังนั้น /(.)/g เหนือฮิรางานะ Shift_JIS
#   สามตัวให้ผลหกชิ้น รูปแบบเดียวกันผ่าน mb::qr ให้สามชิ้น หนึ่งชิ้นต่อ
#   ตัวอักษร ช่วงคลาสอย่าง [a-hiragana ...] เปรียบเทียบตัวอักษรทั้งตัว และ
#   capture คืนค่าตัวอักษรทั้งตัว
#
# ซอร์สเป็น US-ASCII; ข้อมูล multibyte ใช้ไบต์เอสเคป \xHH นี่คือ runtime
# interface (ไม่มี source filter) จึงทำงานบน perl ทุกตัวตั้งแต่ 5.005_03
# ขึ้นไป
#
#     perl eg/th/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# ฮิรางานะ Shift_JIS สามตัว: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# "." ของ CORE คือหนึ่ง octet -- หกชิ้นสำหรับหกไบต์
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") ทำให้ "." เป็นตัวอักษรทั้งตัว -- สามชิ้น คอมไพล์ครั้งเดียว
# แล้วแทรกรูปแบบที่คอมไพล์แล้วลงในการจับคู่
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# ช่วง character-class เหนือบล็อกฮิรางานะ a..n (\x82\xA0-\x82\xF1) ช่วงนี้
# เปรียบเทียบตัวอักษรทั้งตัว ดังนั้น u อยู่ภายในและ "A" แบบ ASCII ไม่อยู่
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# capture คืนค่าตัวอักษร multibyte ทั้งตัว (สองไบต์ที่นี่) ไม่เคยคืนครึ่ง
# ตัว
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# ค้นหาฮิรางานะทุกตัวในสตริงผสม เป็นหน่วยตัวอักษร
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
