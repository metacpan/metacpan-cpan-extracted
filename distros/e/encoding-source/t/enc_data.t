#!perl

use strict;
use warnings;
use encoding::source 'euc-jp';
use Test::More tests => 4;

my @a;

while (<DATA>) {
    chomp;
    tr/ぁ-んァ-ン/ァ-ンぁ-ん/;
    push @a, $_;
}

is(scalar @a, 3);
is($a[0], "コレハDATAふぁいるはんどるノてすとデス。");
is($a[1], "日本語ガチャント変換デキルカ");
is($a[2], "ドウカノてすとヲシテイマス。");

__DATA__
これはDATAファイルハンドルのテストです。
日本語がちゃんと変換できるか
どうかのテストをしています。
