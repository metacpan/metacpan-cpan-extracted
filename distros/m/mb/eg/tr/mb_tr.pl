#!/usr/bin/perl
######################################################################
# eg/tr/mb_tr.pl - mb::tr ile karakter birimli çevriyazım
#
# Ne gösterir:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) bütün çok baytlı
#   KARAKTERLERİ çevriyazar. /r olmadan ilk argümanını yerinde değiştirir
#   ve sayıyı döndürür; /r ile sonucu döndürür ve argümanı dokunmadan
#   bırakır.
#
# CORE ile farkı:
#   CORE tr/// oktet oktet çalışır, bu yüzden bir DAMEMOJI yi bozabilir --
#   İKİNCİ baytı bir ASCII meta-karakteri olan çift baytlı bir karakter,
#   örneğin So(\x83\x5C), ki son baytı \x5C bir ters eğik çizgidir. \x5C
#   üzerinde bir CORE tr o son bayta çarpar; mb::tr So yu tek karakter
#   olarak görür ve ona dokunmaz.
#
# Not: mb::tr de bir tire aralığı (a-z) yalnızca US-ASCII uç noktaları için
# genişletilir; SEARCH içindeki çok baytlı karakterler tek tek listelenmelidir
# (transpiler in bir MBCS tr/// yi genişlettiği biçimle tam olarak aynı).
#
# Not: kaynak ve \xHH verisi US-ASCII kalır; bu dosya UTF-8'dir
# (yalnızca yorumlar Türkçeye yerelleştirildi).
#
#     perl eg/tr/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS ile tam-genişlik rakamlar: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH on tam-genişlik rakamı tek tek listeler; REPLACE US-ASCII aralığı
# "0-9" dur (mb::tr in genişlettiği bir ASCII tire aralığı).
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# Tam-genişlik "1" "3" "6" -> yarı-genişlik "136".
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI güvenliği. Dize A So(\x83\x5C) B. Ters eğik çizgi baytı \x5C yi
# hedefleyen bir CORE tr karakteri bozar; yalnızca ASCII harfleri eşleştiren
# mb::tr So yu bozulmadan bırakır.
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr So nun son baytına çarpar
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r değiştirici: yıkıcı değil, çevriyazılmış kopyayı döndürür.
$keep = "\x82\x50\x82\x51";                 # tam-genişlik 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
