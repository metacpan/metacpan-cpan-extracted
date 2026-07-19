#!/usr/bin/perl
######################################################################
# eg/tr/mb_split.pl - mb::split ile karakter sınırlarında bölme
#
# Ne gösterir:
#   mb::split('', EXPR) bir dizeyi bütün çok baytlı KARAKTERLERE ayırır,
#   mb::split(PATTERN, EXPR) ise MBCS ayracı üzerinden böler ve çok baytlı
#   bir karakterin içindeki bir byte ile asla eşleşmez.
#
# CORE ile farkı:
#   CORE split(//, "\x82\xA0") iki OKTET döndürür ("\x82", "\xA0"); çift
#   baytlı hiragana parçalanır. mb::split('', ...) onu tek karakter olarak
#   döndürür. mb::split, transpile edilmiş "split //" nin çalışma-zamanı
#   karşılığıdır ve Perl 5.005_03 e kadar uyumludur.
#
# Not: kaynak ve \xHH verisi US-ASCII kalır; bu dosya UTF-8'dir
# (yalnızca yorumlar Türkçeye yerelleştirildi).
#
#     perl eg/tr/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS ile üç hiragana: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) byte görür: burada altı tane.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) karakter görür: üç tane.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS ayracı ile bölme. Ayraç hiragana a
# (\x82\xA0); mb::split onu tek karakter olarak eşler, \x82 ya da \xA0
# baytları nerede görünürse görünsün onlarla eşleşmez.
#     A a B a C  ->  alanlar: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# mb::split in liste bağlamında karakter sayımı (bir chars() yardımcısı gibi).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
