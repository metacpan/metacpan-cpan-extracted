#!/usr/bin/perl
######################################################################
# eg/ja/mb_tr.pl - mb::tr による文字単位の変換(トランスリテレーション)
#
# 何を示す例か:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) はマルチバイト「文字」
#   単位で変換する。/r なしなら第1引数をその場で書き換えて件数を返し、
#   /r ありなら結果を返して引数はそのまま残す。
#
# CORE と何が違うか:
#   CORE の tr/// はオクテット単位で動くため、DAMEMOJI ―― 2バイト目が
#   US-ASCII のメタ文字である全角文字、例えば「ソ」(\x83\x5C、後続バイトが
#   バックスラッシュ \x5C)―― を壊しうる。CORE の tr で \x5C を狙うとこの
#   後続バイトに当たってしまうが、mb::tr は「ソ」を1文字として扱い、そのまま
#   残す。
#
# 注意: mb::tr のハイフン範囲(a-z)が展開されるのは US-ASCII の端点だけ。
#   SEARCH のマルチバイト文字は1文字ずつ列挙する(これはトランスパイラが
#   MBCS の tr/// を展開するやり方とまったく同じ)。
#
# ソースは US-ASCII。マルチバイトデータは \xHH バイトエスケープで記述。
#
#     perl eg/ja/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS の全角数字: ０(\x82\x4F) 〜 ９(\x82\x58)。
# SEARCH は全角数字10個を1文字ずつ列挙し、REPLACE は US-ASCII の範囲 "0-9"
# (ASCII のハイフン範囲なので mb::tr が展開する)。
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# 全角「１」「３」「６」 -> 半角「136」。
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI の保全。文字列は A ソ(\x83\x5C) B。CORE の tr でバックスラッシュ
# バイト \x5C を狙うと文字が壊れるが、mb::tr は US-ASCII の英字だけを対象と
# するため「ソ」はそのまま残る。
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE の tr は「ソ」の後続バイトに当たる
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r 修飾子: 非破壊。変換後のコピーを返す。
$keep = "\x82\x50\x82\x51";                 # 全角「１２」
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
