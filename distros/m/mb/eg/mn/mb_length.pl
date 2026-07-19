#!/usr/bin/perl
######################################################################
# eg/mn/mb_length.pl - mb ашиглан тэмдэгт ба байтыг харьцуулан тоолох
#
# Энэ жишээ юуг харуулж байна:
#   CORE-ийн length() нь OCTET (байт) тоолдог; mb::length() нь сонгосон
#   script encoding-ийн дагуу бүтэн multibyte ТЭМДЭГТийг 1 гэж тоолно.
#   mb::substr() ба mb::index() нь мөн тэмдэгтийн нэгжээр ажилладаг тул
#   хоёр байтын тэмдэгт хэзээ ч дундуураа тасрахгүй.
#
# CORE-оос юугаараа ялгаатай вэ:
#   length("\x82\xA0") нь 2 (байт) боловч mb::length("\x82\xA0") нь 1
#   (нэг Shift_JIS хирагана).
#
# Тэмдэглэл: эх код ба \xHH өгөгдөл US-ASCII хэвээр; энэ файл UTF-8 (тайлбар зөвхөн монголоор).
#
#     perl eg/mn/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS-ийн гурван хирагана, нийт зургаан байт:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() байт тоолно; mb::length() тэмдэгт тоолно.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() тэмдэгтийн нэгжээр огтолдог тул хоёр байтын тэмдэгт
# хагасхан таслагдахгүй. Эхний 2 тэмдэгт яг 4 байтын мөр болно.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() байрлалыг байтаар бус тэмдэгтээр мэдээлнэ. Гурав дахь
# тэмдэгт байт 4-өөс эхэлдэг ч тэмдэгтийн индекс 2 дээр байна.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
