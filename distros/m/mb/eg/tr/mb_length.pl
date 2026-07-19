#!/usr/bin/perl
######################################################################
# eg/tr/mb_length.pl - mb ile karakter ve byte sayımını karşılaştırmak
#
# Ne gösterir:
#   CORE length() OKTET (byte) sayar; mb::length() seçili betik
#   kodlamasına göre bütün çok baytlı KARAKTERLERİ sayar. mb::substr()
#   ve mb::index() de karakter biriminde çalışır, böylece çift baytlı bir
#   karakter asla ortadan bölünmez.
#
# CORE ile farkı:
#   length("\x82\xA0") 2 dir (byte), ama mb::length("\x82\xA0") 1 dir
#   (tek bir Shift_JIS hiragana).
#
# Not: kaynak ve \xHH verisi US-ASCII kalır; bu dosya UTF-8'dir
# (yalnızca yorumlar Türkçeye yerelleştirildi).
#
#     perl eg/tr/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS ile üç hiragana, toplam altı byte:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() byte sayar; mb::length() karakter sayar.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() karakter biriminde keser, bu yüzden çift baytlı karakter
# yarıya bölünmez. İlk iki karakter tam olarak 4 baytlık bir dizedir.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() konumu byte olarak değil karakter olarak bildirir. Üçüncü
# karakter byte 4 te başlar, ama karakter indisi 2 dir.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
