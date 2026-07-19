#!/usr/bin/perl
######################################################################
# eg/ja/mb_practical.pl - 文字境界を壊さない固定桁トリミング
#
# 何を示す例か(小さな実務例):
#   固定桁出力のために、Shift_JIS の1行を決まった「表示桁数」に切り詰める。
#   半角文字は1桁、全角文字は2桁として数え(おなじみの 1:2 の比率)、全角
#   (2バイト)文字を桁境界で分断しない。
#
# CORE と何が違うか:
#   素朴な CORE の substr(EXPR, 0, N) は N オクテット目で切るため、先導
#   バイト(lead byte)が宙に浮いた「文字の半分」を残しうる。ここでは
#   mb::split('') で文字を1つずつ辿り、各文字の桁幅をバイト長で測り(1バイト
#   -> 1桁、2バイト -> 2桁)、桁数の予算を超える手前で止める。mb::length()
#   で結果が「文字の整数個」であることを確認する。
#
# ソースは US-ASCII。マルチバイトデータは \xHH バイトエスケープで記述。
# ランタイムインタフェースのみを使うので、Perl 5.005_03 以降で動作する。
#
#     perl eg/ja/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C のあと、全角ひらがな あ い う、続いて半角カタカナ2文字。
#   US-ASCII A B C                      : 各1桁
#   全角 あ(\x82\xA0) い(\x82\xA2) う(\x82\xA4) : 各2桁
#   半角 カ(\xB6) キ(\xB7)                     : 各1桁
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # 表示7桁に切り詰める

# 文字境界を壊さない、桁幅対応のトリミング。
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1バイト -> 1桁、2バイト -> 2桁
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC(3桁) + あ(2) + い(2) = 7桁。う は予算超過で捨てられるので、末尾の全角
# 文字は丸ごと残る。
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# 対比(全角のみのデータ): 固定オクテット数で切ると文字の内側に入りうる。
# ひらがな あ い う は全て2バイトなので、バイト長が奇数なら文字を分断した
# ことを意味する。mb::substr は常に文字境界で止まる(ここではバイト長が偶数)。
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # あ + 宙に浮いた先導バイト
$char_cut  = mb::substr($aiu, 0, 1);    # ちょうど あ
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
