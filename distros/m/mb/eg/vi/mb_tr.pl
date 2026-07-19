#!/usr/bin/perl
######################################################################
# eg/vi/mb_tr.pl - chuyen doi ky tu theo don vi ky tu bang mb::tr
#
# Vi du nay cho thay:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) chuyen doi tron ky tu
#   da byte. Khong co /r thi sua doi so mot tai cho va tra ve so dem;
#   co /r thi tra ve ket qua va giu nguyen doi so.
#
# Khac CORE the nao:
#   CORE tr/// lam theo tung byte nen co the pha hong DAMEMOJI -- ky tu
#   hai byte co byte thu hai la meta ASCII (vd So \x83\x5C, byte cuoi
#   \x5C la dau gach cheo nguoc). mb::tr xem So la mot ky tu, giu nguyen.
#
# Luu y: trong mb::tr, dai gach noi (a-z) chi mo rong cho dau mut US-ASCII;
# ky tu da byte trong SEARCH phai liet ke tung cai mot.
#
# Ghi chu: ma nguon va du lieu \xHH giu US-ASCII; tep nay la UTF-8 (chi comment tieng Viet).
#
#     perl eg/vi/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Full-width digits in Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH liet ke ca muoi chu so day du nhu tron ky tu; REPLACE la dai
# US-ASCII "0-9" (mot dai gach noi ASCII, ma mb::tr mo rong).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# Day du "1" "3" "6" -> nua chieu "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# An toan DAMEMOJI. Chuoi la A So(\x83\x5C) B. Mot CORE tr nham vao byte
# gach cheo nguoc \x5C se pha hong ky tu; mb::tr chi anh xa chu ASCII nen
# giu nguyen So.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr trung byte cuoi cua So
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# Bo tu chinh /r: khong pha huy, tra ve ban sao da chuyen doi.
$keep = "\x82\x50\x82\x51";                 # day du 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
