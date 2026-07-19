#!/usr/bin/perl
######################################################################
# eg/th/mb_tr.pl - การถอดอักษรระดับตัวอักษรด้วย mb::tr
#
# ตัวอย่างนี้แสดงอะไร:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) ถอดอักษรตัวอักษร multibyte
#   ทั้งตัว หากไม่มี /r มันจะแก้ไขอาร์กิวเมนต์แรกในที่เดิมและคืนค่าจำนวน
#   นับ; หากมี /r มันจะคืนค่าผลลัพธ์และไม่แตะต้องอาร์กิวเมนต์
#
# ต่างจาก CORE อย่างไร:
#   CORE tr/// ทำงานทีละ octet จึงอาจทำให้ DAMEMOJI เสียหาย -- ตัวอักษร
#   สองไบต์ที่ไบต์ที่สองเป็น metacharacter ของ ASCII เช่น So(\x83\x5C)
#   ซึ่งไบต์ท้าย \x5C คือ backslash CORE tr บน \x5C จะไปโดนไบต์ท้ายนั้น;
#   mb::tr เห็น So เป็นตัวอักษรเดียวและปล่อยไว้
#
# หมายเหตุ: ใน mb::tr ช่วงยัติภังค์ (a-z) ถูกขยายเฉพาะปลายที่เป็น US-ASCII
# เท่านั้น; ตัวอักษร multibyte ใน SEARCH ต้องระบุทีละตัว (ตรงตามที่
# transpiler ขยาย tr/// แบบ MBCS)
#
# ซอร์สเป็น US-ASCII; ข้อมูล multibyte ใช้ไบต์เอสเคป \xHH
#
#     perl eg/th/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# ตัวเลขเต็มความกว้างใน Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58) SEARCH ระบุ
# ตัวเลขเต็มความกว้างทั้งสิบตัวเป็นตัวอักษรทั้งตัว; REPLACE คือช่วง US-ASCII
# "0-9" (ช่วงยัติภังค์ ASCII ซึ่ง mb::tr ขยายให้)
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# เต็มความกว้าง "1" "3" "6" -> ครึ่งความกว้าง "136"
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# ความปลอดภัยของ DAMEMOJI สตริงคือ A So(\x83\x5C) B CORE tr ที่เล็งไบต์
# backslash \x5C ทำให้ตัวอักษรเสียหาย; mb::tr ซึ่งแมปเฉพาะตัวอักษร ASCII
# ปล่อย So ไว้ครบถ้วน
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr ไปโดนไบต์ท้ายของ So
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# ตัวปรับ /r: ไม่ทำลายของเดิม คืนสำเนาที่ถอดอักษรแล้ว
$keep = "\x82\x50\x82\x51";                 # เต็มความกว้าง 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
