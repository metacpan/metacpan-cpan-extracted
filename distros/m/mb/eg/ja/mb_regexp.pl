#!/usr/bin/perl
######################################################################
# eg/ja/mb_regexp.pl - mb::qr によるマルチバイト対応の正規表現マッチ
#
# 何を示す例か:
#   mb::qr(PATTERN) は、"." や文字クラス、キャプチャが、選択したスクリプト
#   エンコーディングにおける「マルチバイト文字」単位で働く正規表現を
#   コンパイルする。
#
# CORE と何が違うか:
#   CORE の "." は1オクテットにマッチするので、Shift_JIS のひらがな3文字に
#   対する /(.)/g は6個を返す。同じパターンを mb::qr 経由にすると、1文字ずつ
#   3個を返す。文字クラスの範囲 [あ-ん] は文字同士を比較し、キャプチャは
#   1文字を丸ごと返す。
#
# ソースは US-ASCII。マルチバイトデータは \xHH バイトエスケープで記述。
# これはランタイムインタフェース(ソースフィルタ非使用)なので、
# Perl 5.005_03 以降のすべてで動作する。
#
#     perl eg/ja/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS のひらがな3文字: あ(\x82\xA0) い(\x82\xA2) う(\x82\xA4)。
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE の "." は1オクテット。6バイトなので6個。
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") にすると "." が1文字になり3個。一度コンパイルしてから、
# コンパイル済みパターンをマッチに展開する。
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# ひらがなブロック あ..ん(\x82\xA0-\x82\xF1)を範囲とする文字クラス。
# 範囲は文字同士を比較するので「う」は範囲内、US-ASCII の "A" は範囲外。
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# キャプチャはマルチバイト文字を丸ごと(ここでは2バイト)返し、半分だけを
# 返すことはない。
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# 混在文字列から、ひらがなを文字単位で全て取り出す。
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
