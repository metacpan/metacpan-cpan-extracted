#!/usr/bin/perl
######################################################################
# eg/ja/mb_split.pl - mb::split による文字境界での分割
#
# 何を示す例か:
#   mb::split('', EXPR) は文字列をマルチバイト「文字」単位に分割する。
#   mb::split(PATTERN, EXPR) は MBCS の区切り文字で分割するが、マルチ
#   バイト文字の内側にあるバイトを誤って区切りにすることがない。
#
# CORE と何が違うか:
#   CORE の split(//, "\x82\xA0") は2つのオクテット("\x82","\xA0")を返し、
#   全角ひらがなが引き裂かれる。mb::split('', ...) は1文字として返す。
#   mb::split は、トランスパイル時の "split //" に対応するランタイム版で、
#   Perl 5.005_03 まで互換に動作する。
#
# ソースは US-ASCII。マルチバイトデータは \xHH バイトエスケープで記述。
#
#     perl eg/ja/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS のひらがな3文字: あ(\x82\xA0) い(\x82\xA2) う(\x82\xA4)。
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE の split(//, ...) はバイトを見る。ここでは6個。
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) は文字を見る。ここでは3個。
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS の区切り文字での分割。区切りはひらがな「あ」(\x82\xA0)。mb::split は
# これを1つの文字として扱い、\x82 や \xA0 が別の場所に現れても誤爆しない。
#     A あ B あ C  ->  フィールド: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# リストコンテキストの mb::split による文字数カウント(chars() 相当)。
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
