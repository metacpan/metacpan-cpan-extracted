#!/usr/bin/perl
######################################################################
# eg/mn/mb_regexp.pl - mb::qr ашиглан multibyte-мэдэрдэг тааруулалт
#
# Энэ жишээ юуг харуулж байна:
#   mb::qr(PATTERN) нь ".", character class болон capture нь сонгосон
#   script encoding-ийн дагуу бүтэн multibyte ТЭМДЭГТээр ажилладаг
#   регуляр илэрхийллийг compile хийдэг.
#
# CORE-оос юугаараа ялгаатай вэ:
#   CORE "." нь ганц OCTET-тэй тохирдог тул гурван Shift_JIS хирагана дээр
#   /(.)/g нь зургаан хэсэг гаргана. Ижил загвар mb::qr-ээр гурван хэсэг,
#   тэмдэгт тус бүр нэг гаргана. [a-hiragana ...] мэт class муж нь бүтэн
#   тэмдэгтүүдийг харьцуулдаг, capture нь бүтэн тэмдэгт буцаадаг.
#
# Эх нь US-ASCII; multibyte өгөгдөл \xHH байт escape ашиглана. Энэ нь
# runtime интерфейс (source filter байхгүй) тул 5.005_03-аас дээш бүх
# perl дээр ажиллана.
#
#     perl eg/mn/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS-ийн гурван хирагана: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE "." нь нэг octet -- зургаан байтад зургаан хэсэг.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") нь "."-г бүтэн тэмдэгт болгоно -- гурван хэсэг. Нэг удаа
# compile хийж, дараа нь compile хийсэн загварыг тааруулалтад оруулна.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# a..n хирагана блок дээрх character-class муж (\x82\xA0-\x82\xF1). Муж нь
# бүтэн тэмдэгтүүдийг харьцуулдаг тул u дотор нь орно, ASCII "A" орохгүй.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# capture нь бүтэн multibyte тэмдэгт (энд хоёр байт) буцаадаг, хэзээ ч
# түүний хагасыг биш.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Холимог мөр дэх хирагана бүрийг тэмдэгтийн нэгжээр олох.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
