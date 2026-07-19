#!/usr/bin/perl
######################################################################
# eg/ja/mb_length.pl - mb による文字数とバイト数の違い
#
# 何を示す例か:
#   CORE の length() は「オクテット(バイト)」を数えるが、mb::length()
#   は選択したスクリプトエンコーディングにおける「マルチバイト文字」を
#   1文字として数える。mb::substr() と mb::index() も文字単位で動くため、
#   全角(2バイト)文字を途中で断ち切ることがない。
#
# CORE と何が違うか:
#   length("\x82\xA0") は 2(バイト)だが、mb::length("\x82\xA0") は 1
#   (Shift_JIS のひらがな「あ」1文字)。
#
# ソースはあえて US-ASCII とし、マルチバイトデータは \xHH バイトエスケープ
# で記述する。こうすると可搬性を保ったまま、mb はそのバイト列を1つの文字
# として扱う。配布ルートから(またはインストール後に)実行する:
#
#     perl eg/ja/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS のひらがな3文字、合計6バイト:
#     \x82\xA0  あ   \x82\xA2  い   \x82\xA4  う
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE の length() はバイトを、mb::length() は文字を数える。
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() は文字単位で切り出すので、全角文字が半分に切れることはない。
# 先頭2文字はきっかり4バイトの文字列になる。
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() は位置をバイトではなく文字で返す。3文字目はバイト位置4だが、
# 文字インデックスでは2。
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
