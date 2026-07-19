#!/usr/bin/perl
######################################################################
# eg/tr/mb_practical.pl - çift baytlıyı bozmadan sabit-sütun kırpma
#
# Ne gösterir (küçük bir gerçek görev):
#   Bir Shift_JIS satırını sabit-sütun çıktı için sabit bir GÖRÜNTÜ
#   GENİŞLİĞİNE kırp; yarı-genişlik karakteri 1 sütun, tam-genişlik
#   karakteri 2 sütun say (klasik 1:2 oranı) ve çift baytlı bir karakteri
#   sınırdan asla bölme.
#
# CORE ile farkı:
#   Saf bir CORE substr(EXPR, 0, N) N inci OKTETTE keser ve sarkan bir
#   önder byte -- karakterin bozuk bir yarısı -- bırakabilir. Burada bütün
#   karakterleri mb::split('') ile dolaşırız, her karakterin genişliğini
#   byte uzunluğundan ölçeriz (1 byte -> 1 sütun, 2 byte -> 2 sütun) ve
#   bütçe aşılmadan önce dururuz. mb::length() sonucun tam sayıda karakter
#   olduğunu doğrular.
#
# Not: kaynak ve \xHH verisi US-ASCII kalır; bu dosya UTF-8'dir
# (yalnızca yorumlar Türkçeye yerelleştirildi).
#
#     perl eg/tr/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C sonra üç tam-genişlik hiragana a i u sonra iki yarı-genişlik katakana.
#   ASCII A B C            : her biri 1 sütun
#   tam-genişlik a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : her biri 2 sütun
#   yarı-genişlik ka(\xB6) ki(\xB7)                   : her biri 1 sütun
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # 7 görüntü sütununa kırp

# Karakter-sınırına güvenli, genişlik-farkındalıklı kırpma.
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 byte -> 1 sütun, 2 byte -> 2 sütun
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 sütun) + a (2) + i (2) = 7 sütun; u taşardı ve düşürülür, böylece
# sondaki çift baytlı karakter bütün kalır.
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# Yalnızca çift baytlı veri üzerinde karşılaştırma: sabit bir OKTET sayısında
# kesmek bir karakterin içine düşebilir. Hiragana a i u tamamen çift baytlıdır,
# bu yüzden tek sayı bir byte uzunluğu kesimin bir karakteri böldüğünü gösterir;
# mb::substr her zaman bir karakter sınırında durur (burada çift byte uzunluğu).
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + sarkan bir önder byte
$char_cut  = mb::substr($aiu, 0, 1);    # tam olarak a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
