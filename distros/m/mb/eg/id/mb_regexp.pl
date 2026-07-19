#!/usr/bin/perl
######################################################################
# eg/id/mb_regexp.pl - pencocokan sadar-multibyte dengan mb::qr
#
# Apa yang ditunjukkan:
#   mb::qr(PATTERN) mengompilasi ekspresi reguler yang ".", kelas
#   karakter, dan capture-nya bekerja dalam KARAKTER multibyte utuh
#   menurut script encoding yang dipilih.
#
# Bedanya dengan CORE:
#   "." pada CORE cocok dengan satu OKTET, jadi /(.)/g atas tiga hiragana
#   Shift_JIS menghasilkan enam potong. Pola yang sama lewat mb::qr
#   menghasilkan tiga, satu per karakter. Rentang kelas seperti
#   [a-hiragana ...] membandingkan karakter utuh, dan capture
#   mengembalikan karakter utuh.
#
# Sumber ini US-ASCII; data multibyte memakai escape byte \xHH. Ini
# antarmuka runtime (tanpa source filter), jadi jalan pada setiap perl
# dari 5.005_03 ke atas.
#
#     perl eg/id/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Tiga hiragana Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# "." CORE adalah satu oktet -- enam potong untuk enam byte.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") membuat "." satu karakter utuh -- tiga potong. Kompilasi
# sekali, lalu sisipkan pola terkompilasi itu ke dalam pencocokan.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# Rentang kelas karakter atas blok hiragana a..n (\x82\xA0-\x82\xF1).
# Rentang membandingkan karakter utuh, jadi u ada di dalam dan "A" ASCII tidak.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# Capture mengembalikan karakter multibyte utuh (dua byte di sini),
# tidak pernah separuhnya.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Temukan setiap hiragana dalam string campuran, dalam satuan karakter.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
