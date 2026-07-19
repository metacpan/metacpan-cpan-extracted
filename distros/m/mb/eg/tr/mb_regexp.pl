#!/usr/bin/perl
######################################################################
# eg/tr/mb_regexp.pl - mb::qr ile çok baytlı farkındalıklı eşleşme
#
# Ne gösterir:
#   mb::qr(PATTERN) öyle bir düzenli ifade derler ki "." , karakter
#   sınıfları ve yakalamalar seçili betik kodlamasına göre bütün çok
#   baytlı KARAKTERLER üzerinde çalışır.
#
# CORE ile farkı:
#   CORE "." tek bir OKTET eşler, bu yüzden üç Shift_JIS hiragana üzerinde
#   /(.)/g altı parça verir. Aynı desen mb::qr üzerinden üç verir, karakter
#   başına bir. [a-hiragana ... ] gibi bir sınıf aralığı bütün karakterleri
#   karşılaştırır ve bir yakalama bütün bir karakter döndürür.
#
# Not: kaynak ve \xHH verisi US-ASCII kalır; bu dosya UTF-8'dir
# (yalnızca yorumlar Türkçeye yerelleştirildi).
#
#     perl eg/tr/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS ile üç hiragana: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE "." bir oktettir -- altı byte için altı parça.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") "." yi tek bir bütün karakter yapar -- üç parça. Bir kez
# derle, sonra derlenmiş deseni eşleşmeye yerleştir.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# Hiragana bloğu a..n (\x82\xA0-\x82\xF1) üzerinde karakter-sınıfı aralığı.
# Aralık bütün karakterleri karşılaştırır, böylece u içerdedir, ASCII "A" değil.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# Yakalama bütün bir çok baytlı karakter döndürür (burada iki byte), asla
# yarısını değil.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Karışık bir dizedeki her hiraganayı karakter biriminde bul.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
