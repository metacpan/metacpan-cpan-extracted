#!/usr/bin/perl
######################################################################
# eg/th/mb_length.pl - นับตัวอักษรเทียบกับไบต์ด้วย mb
#
# ตัวอย่างนี้แสดงอะไร:
#   length() ของ CORE นับ OCTET (ไบต์); mb::length() นับตัวอักษร multibyte
#   ทั้งตัวตาม script encoding ที่เลือก mb::substr() และ mb::index() ก็
#   ทำงานเป็นหน่วยตัวอักษรด้วย ดังนั้นตัวอักษรสองไบต์จึงไม่ถูกตัดครึ่ง
#
# ต่างจาก CORE อย่างไร:
#   length("\x82\xA0") เท่ากับ 2 (ไบต์) แต่ mb::length("\x82\xA0") เท่ากับ 1
#   (ฮิรางานะ Shift_JIS หนึ่งตัว)
#
# หมายเหตุ: ซอร์สและข้อมูล \xHH ยังคงเป็น US-ASCII; ไฟล์นี้เป็น UTF-8 (คอมเมนต์เป็นภาษาไทยเท่านั้น)
#
#     perl eg/th/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# ฮิรางานะ Shift_JIS สามตัว รวมหกไบต์:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# length() ของ CORE นับไบต์; mb::length() นับตัวอักษร
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() ตัดเป็นหน่วยตัวอักษร ตัวอักษรสองไบต์จึงไม่ถูกผ่าครึ่ง
# ตัวอักษร 2 ตัวแรกเป็นสตริงขนาด 4 ไบต์พอดี
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() รายงานตำแหน่งเป็นตัวอักษร ไม่ใช่ไบต์ ตัวอักษรตัวที่สามเริ่ม
# ที่ไบต์ 4 แต่ที่ดัชนีตัวอักษร 2
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
