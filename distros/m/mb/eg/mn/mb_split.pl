#!/usr/bin/perl
######################################################################
# eg/mn/mb_split.pl - mb::split ашиглан тэмдэгтийн зааг дээр салгах
#
# Энэ жишээ юуг харуулж байна:
#   mb::split('', EXPR) нь мөрийг бүтэн multibyte ТЭМДЭГТ болгон задалдаг,
#   mb::split(PATTERN, EXPR) нь multibyte тэмдэгтийн дотор орших байттай
#   хэзээ ч тохирохгүйгээр MBCS хязгаарлагч дээр салгадаг.
#
# CORE-оос юугаараа ялгаатай вэ:
#   CORE split(//, "\x82\xA0") нь хоёр OCTET ("\x82", "\xA0") буцаадаг;
#   хоёр байтын хирагана хуваагдана. mb::split('', ...) нь үүнийг нэг
#   тэмдэгт болгон буцаана. mb::split нь transpile хийсэн "split //"-ийн
#   runtime-д удирдагддаг хос бөгөөд Perl 5.005_03 хүртэл нийцтэй.
#
# Эх нь US-ASCII; multibyte өгөгдөл \xHH байт escape ашиглана.
#
#     perl eg/mn/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS-ийн гурван хирагана: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) байт хардаг: энд зургаа.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) тэмдэгт хардаг: энд гурав.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS хязгаарлагч дээр салгах. Хязгаарлагч нь хирагана a (\x82\xA0);
# mb::split үүнийг бүтэн тэмдэгт болгон тохируулдаг, тэдгээр байт хаана
# ч тохиолдсон \x82 эсвэл \xA0 байт болгож биш.
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# mb::split-ийн list context-оор тэмдэгтийн тоог гаргах (chars() туслах шиг).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
