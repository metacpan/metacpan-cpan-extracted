#!/usr/bin/perl
######################################################################
# eg/vi/mb_length.pl - dem ky tu so voi byte bang mb
#
# Vi du nay cho thay:
#   length() cua CORE dem OCTET (byte); mb::length() dem tron ky tu
#   da byte theo script encoding da chon. mb::substr() va mb::index()
#   cung lam viec theo don vi ky tu, ky tu hai byte khong bi cat doi.
#
# Khac CORE the nao:
#   length cua hiragana hai byte la 2 (byte), nhung mb::length la 1
#   (mot ky tu hiragana Shift_JIS).
#
# Ghi chu: ma nguon va du lieu \xHH giu US-ASCII; tep nay la UTF-8 (chi comment tieng Viet).
#
#     perl eg/vi/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Ba hiragana Shift_JIS, tong cong sau byte:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# length() cua CORE dem byte; mb::length() dem ky tu.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() cat theo don vi ky tu nen ky tu hai byte khong bi cat doi.
# Hai ky tu dau la mot chuoi 4 byte tron ven.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() bao vi tri theo ky tu, khong phai byte. Ky tu thu ba bat
# dau o byte 4 nhung o chi so ky tu 2.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
